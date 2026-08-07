# Kapsis - Plugin API for building CLI commands
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis
##
## This module is imported by plugins (shared libraries) that extend a CLI
## application made with Kapsis. It provides the `commands` DSL used to declare
## subcommands from inside a `pluginkit` plugin, together with the JSON bridge that
## marshals the raw command-line arguments sent by the host into the typed `Values`
## handed to every command handler.

import std/[macros, strutils, json, tables, os, parseopt, macrocache]

import ./types
import ./runtime
import pkg/pluginkit/readers

export types, runtime
export parseopt

type
  PluginArg* {.inject.} = object
    ## A command-line argument definition declared by a plugin command.
    name*: string
      ## The name of the argument, used to reference it inside the command handler
    datatype*: CmdArgValueType
      ## The expected type of the argument, used for parsing and validation
    kind*: CmdLineKind
      ## The kind of the argument (`cmdArgument`, `cmdLongOption` or `cmdShortOption`)
    optional*: bool
      ## Whether the argument is optional

proc toValueType*(s: string): CmdArgValueType =
  ## Parses a type string (e.g. `"string"`, `"int"`) into a `CmdArgValueType`.
  parseEnum[CmdArgValueType](s)

proc argKind(kind: CmdLineKind): string {.compileTime.} =
  result = case kind
    of cmdArgument: "argument"
    of cmdLongOption: "longOption"
    of cmdShortOption: "shortOption"
    else: "argument"

proc toCamel(name: string): string =
  ## Converts a command name (possibly dotted, dashed or space separated) into a
  ## valid CamelCase Nim identifier, e.g. `colors.blue` -> `colorsBlue`.
  result = ""
  var i = 0
  while i < name.len:
    case name[i]
    of '-', '_', ' ', '.':
      inc(i)
      if i < name.len:
        result.add(name[i].toUpperAscii)
    else:
      result.add(name[i])
    inc(i)

proc jsonArgsToValues*(json: string, specs: openArray[PluginArg]): ValuesTable =
  ## Parses a JSON object of raw string arguments into a typed `ValuesTable`,
  ## reusing kapsis' runtime validation via `collectValues`.
  var node: JsonNode
  try:
    node = parseJson(json)
  except CatchableError:
    node = newJObject()
  result = initOrderedTable[string, Value]()
  for spec in specs:
    if node.hasKey(spec.name):
      collectValues(result, spec.name, node[spec.name].getStr, spec)
    elif spec.datatype == ktBool and not spec.optional:
      # an absent (non-optional) boolean flag defaults to `true` when present here
      collectValues(result, spec.name, "true", spec)

proc parseArgList(cmdArgs: seq[NimNode]): (seq[NimNode], seq[PluginArg]) =
  ## Parses the argument definitions of a plugin command. Returns the raw AST nodes
  ## and the runtime `PluginArg` specs.
  var
    argNodes: seq[NimNode]
    specs: seq[PluginArg]
  for n in cmdArgs:
    var
      isOptional = false
      argTypeNode, argNameNode: NimNode
      kind = cmdArgument
    case n.kind
    of nnkDotExpr:
      argTypeNode = n[1]
      argNameNode = n[0]
    of nnkCommand, nnkCall:
      argTypeNode = n[0]
      argNameNode = n[1]
      if argNameNode.kind == nnkStrLit:
        if argNameNode.strVal.startsWith("--"):
          kind = cmdLongOption
        elif argNameNode.strVal.startsWith("-"):
          kind = cmdShortOption
    of nnkPrefix:
      if n[0].eqIdent("?"):
        isOptional = true
        if n[1].kind == nnkDotExpr:
          argTypeNode = n[1][1]
          argNameNode = n[1][0]
        elif n[1].kind in {nnkCommand, nnkCall}:
          argTypeNode = n[1][0]
          argNameNode = n[1][1]
          if argNameNode.kind == nnkStrLit:
            if argNameNode.strVal.startsWith("--"):
              kind = cmdLongOption
            elif argNameNode.strVal.startsWith("-"):
              kind = cmdShortOption
        else:
          error("Invalid argument definition (" & $n.kind & "): " & n.repr, n)
      else:
        error("Invalid argument definition (" & $n.kind & "): " & n.repr, n)
    else:
      error("Invalid argument definition (" & $n.kind & "): " & n.repr, n)

    specs.add PluginArg(
      name: argNameNode.strVal,
      datatype: parseEnum[CmdArgValueType](argTypeNode.strVal),
      kind: kind,
      optional: isOptional
    )
    argNodes.add(n)
  result = (argNodes, specs)

proc buildArgLiteral(specs: seq[PluginArg]): NimNode =
  ## Builds the array literal of `PluginArg` values for a command.
  result = nnkBracket.newTree()
  for s in specs:
    result.add(
      nnkObjConstr.newTree(
        ident"PluginArg",
        nnkExprColonExpr.newTree(ident"name", newLit(s.name)),
        nnkExprColonExpr.newTree(ident"datatype",
          newCall(ident"toValueType", newLit($s.datatype))),
        nnkExprColonExpr.newTree(ident"kind", ident($s.kind)),
        nnkExprColonExpr.newTree(ident"optional", newLit(s.optional))
      )
    )

macro commands*(bodies: untyped): untyped =
  ## Declares CLI commands contributed by a kapsis plugin. Each leaf command is
  ## turned into an exported `plugin_command_<name>` entrypoint the host can invoke,
  ## and a manifest is registered in the compile-time `PluginStorage` cache which
  ## the pluginkit `plugin` macro later emits as `plugin_event_load_commands`.
  var manifest = newJArray()
  var runners = newStmtList()

  proc isSubCommand(n: NimNode): bool =
    ## `true` when `n` is a nested command declaration (i.e. a `name ...:` block)
    ## as opposed to an ordinary statement such as a `echo` call.
    n.kind in {nnkCommand, nnkCall} and
      n.len >= 2 and n[^1].kind in {nnkStmtList, nnkStmtListExpr}

  proc parse(cmds: NimNode, prefix: string) =
    for cmd in cmds:
      var
        name = ""
        cmdArgs: seq[NimNode]
        cmdBody: NimNode
      case cmd.kind
      of nnkCommand, nnkCall:
        name = cmd[0].strVal
        # the trailing node is the command body; everything in between are args,
        # mirroring the way kapsis' own `parseCommand` handles them
        cmdBody = cmd[^1]
        for i in 1..<cmd.len - 1:
          cmdArgs.add(cmd[i])
      else:
        error("Invalid command definition in a `commands do:` block", cmd)

      let fullName =
        if prefix.len > 0: prefix & "." & name else: name

      # detect nested commands (groups)
      var isGroup = false
      if cmdBody.kind == nnkStmtList:
        for nt in cmdBody:
          if nt.kind == nnkCommentStmt:
            continue
          if nt.isSubCommand():
            isGroup = true
            break
      if isGroup:
        var sub = newNimNode(nnkStmtList)
        for nt in cmdBody:
          if nt.kind == nnkCommentStmt:
            continue
          if nt.isSubCommand():
            sub.add(nt)
        parse(sub, fullName)
        continue

      var description = ""
      var userBody = newStmtList()
      if cmdBody.kind == nnkStmtList:
        for j, nt in cmdBody:
          if j == 0 and nt.kind == nnkCommentStmt:
            description = nt.strVal.strip()
          else:
            userBody.add(nt)
      else:
        userBody.add(cmdBody)

      let (_, specs) = parseArgList(cmdArgs)
      let camel = toCamel(name)
      let symbolName = "plugin_command_" & camel
      let symbolIdent = ident(symbolName)
      let argLiteral = buildArgLiteral(specs)

      var commandObj = newJObject()
      commandObj["name"] = %fullName
      commandObj["description"] = %description
      commandObj["symbol"] = %symbolName
      var argsArr = newJArray()
      for s in specs:
        var a = newJObject()
        a["name"] = %s.name
        a["type"] = %(($s.datatype))
        a["kind"] = %argKind(s.kind)
        a["optional"] = %s.optional
        argsArr.add(a)
      commandObj["args"] = argsArr
      manifest.add(commandObj)

      runners.add quote do:
        proc `symbolIdent`(json: cstring): cstring =
          try:
            let raw =
              if json.isNil: ""
              else: $json
            var vals: ValuesTable = jsonArgsToValues(raw, `argLiteral`)
            block:
              let v {.inject.} = addr vals
              `userBody`
            result = cstring("{}")
          except CatchableError:
            result = cstring("{\"error\": \"failed\"}")

  parse(bodies, "")
  PluginStorage["commands"] = newLit($manifest)
  PluginStorage["commandRunners"] = runners