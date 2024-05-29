# Kapsis - Build delightful command line
# interfaces in seconds
# 
#   (c) 2024 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import std/[macros, macrocache, os, times, tables,
  strutils, sequtils, parseopt, json, oids, enumutils]

import pkg/[voodoo, checksums/md5]

from std/algorithm import sorted, SortOrder
import ./cli

export tables, parseopt, os, cli, expandGetters

type
  KapsisArgType* = enum
    katArg
    katVariant

  KapsisPath* = object
    file*: FileInfo
    path*: string

  KapsisValueType* = enum
    vtString = "string"
    vtBool = "bool"
    vtInt = "int"
    vtFloat = "float"
    vtFile = "file"
    vtPath = "path"
    vtFilename = "filename"
    vtDir = "dir"
    vtMilliseconds = "miliseconds"
    vtSeconds = "seconds"
    vtMinutes = "minutes"
    vtHours = "hours"
    vtDays = "days"
    vtMonths = "months"
    vtYears = "years"
    vtJson = "json"
    vtYaml = "yaml"


  KapsisErrorMessage* = enum
    unknownOption = "Unknown option flag `$1`"
    unknownCommand = "Unknown command `$1`"
    unexpectedOption = "Unexpected argument `$1`"
    typeMismatch = "Type mismatch `$1` argument expect `$2`"
    missingArgument = "Missing argument `$1` type of $2"
    missingArg = "Missing option `$1`"

  KapsisArgument* = object
    lkind: CmdLineKind
    datatype: KapsisValueType
    isOptional: bool
    case argtype: KapsisArgType
    of katVariant:
      argVariant: seq[string]
      argVariantDesc: seq[string]
    else: discard
    desc: string
      # additional info used to describe the arg 
  
  Value* {.getters.} = object
    case vt: KapsisValueType
    of vtString:
      vStr: string
    of vtBool:
      vBool: bool
    of vtInt:
      vInt: int
    of vtFloat:
      vFloat: float
    of vtFile:
      vFile: KapsisPath
    of vtPath:
      vPath: KapsisPath
    of vtFilename:
      vFilename: string
    of vtDir:
      vDir: KapsisPath
    of vtMilliseconds:
      vMilliseconds: Duration
    of vtSeconds:
      vSeconds: Duration
    of vtMinutes:
      vMinutes: Duration
    of vtHours:
      vHours: Duration
    of vtDays:
      vDays: Duration
    of vtMonths:
      vMonths: Duration
    of vtYears:
      vYears: Duration
    of vtJson:
      vJson: JsonNode
    of vtYaml:
      vYaml: string

  ValuesTable = OrderedTable[string, Value]
  Values* = ptr ValuesTable

  KapsisCommandType* = enum
    ctCmd
    ctCmdDir # a list with commands
    ctCmdSep # command separator

  KapsisCommand* = ref object
    case ctype: KapsisCommandType
    of ctCmd:
      id: string
        # the command name
      args: OrderedTable[string, KapsisArgument]
        # an ordered table containing all arguments
      argsIndex: seq[(CmdLineKind, string)]
        # keep indexing the registered arguments
      callback: proc(v: Values) {.nimcall.}
        # the command callback 
      isSubCmd: bool
    of ctCmdSep:
      label: string
    of ctCmdDir:
      idDir: string
        # dir name
      list: OrderedTableRef[string, KapsisCommand]
        # an ordered table containing sub commands
    desc: string
      # improve UX by describing each command, 
      # thanks to Nim's macro-system we can use
      # doc comments `##` to describe the commands

  KapsisInput* = tuple[kind: CmdLineKind, key: string, val: string]

  KapsisSettings = object
    usageIndent = 2
    mainCommandId: string

  KapsisCli = ref object
    pkg*: tuple[description, version, author, license: string]
    commands = newOrderedTable[string, KapsisCommand]()
    mainCommand: KapsisCommand
    settings: KapsisSettings

var Kapsis* = KapsisCli()

#
# Runtime functions
#
template printError*(msg: KapsisErrorMessage, arg: varargs[string]) =
  ## Print `msg` error with `args` and quit with `QuitFailure` exit code 
  if arg.len == 0:
    display("\e[31mError:\e[0m " & $(msg))
  else:
    display("\e[31mError:\e[0m " & $(msg) % arg)
  quit(QuitFailure)

proc outputCommand(cmd: KapsisCommand,
    output: var seq[(string, string)],
    cmdlen: var seq[int], showtype = false) =
  var str = indent(cmd.id, Kapsis.settings.usageIndent)
  for x, arg in cmd.args:
    case arg.lkind
    of cmdArgument:
      case arg.argtype
      of katArg:
        var i = (if arg.isOptional: 4 else: 3)
        inc cmdlen[^1], (x.len + i) # count `<` `arg` `>` includes 1 ws indent
        add str, indent(("\e[90m<$1\e[0m" % [if arg.isOptional: "?" else: ""]), 1)
        add str, x
        if showtype:
          add str, "\e[36m:" & $(arg.datatype) & "\e[0m"
          inc cmdlen[^1], (len($(arg.datatype)) + 1)
        add str, "\e[90m>\e[0m"
      of katVariant:
        inc cmdlen[^1], (x.len + 3) # count `<` `arg` `>` includes 1 ws indent
        add str, indent("\e[90m[\e[0m", 1)
        add str, arg.argVariant.join("\e[90m|\e[0m")
        inc cmdlen[^1], arg.argVariant.join("|").len
        if showtype:
          add str, "\e[36m:" & $(arg.datatype) & "\e[0m"
          inc cmdlen[^1], (len($(arg.datatype)) + 1)
        add str, "\e[90m]\e[0m"
    of cmdLongOption:
      inc cmdlen[^1], (x.len + 1)
      add str, indent(x, 1)
    of cmdShortOption:
      inc cmdlen[^1], (x.len + 1)
      add str, indent(x, 1)
    else: discard
  add output[^1][0], str  
  add output[^1][1], "\e[90m" & cmd.desc & "\e[0m"
  # if cmd.desc.len > 0:
    # add output[^1][1], "\n"
  # else:
    # add output[^1][0], "\n"

proc printUsage*(showExtras = false, showCommand = "",
    showSubCommands = false) =
  var output: seq[(string, string)] # output lines
  var cmdlen: seq[int]
  if showCommand.len > 0:
    # print usage of a specific command
    let cmd = Kapsis.commands[showCommand]
    if not showSubCommands:
      add output, ("", "")
      add cmdlen, cmd.id.len
      cmd.outputCommand(output, cmdlen, true)
    else:
      add output, ("", "")
      add output[0][0], "\e[90m" & cmd.desc & "\e[0m"
      for subk, subcmd in cmd.list:
        add output, ("", "")
        add cmdlen, subcmd.id.len
        subcmd.outputCommand(output, cmdlen, true)
  if showExtras:
    add output, ("", "")
    add output[0][0], "\e[90m" & Kapsis.pkg.description & "\n"
    add output[0][0], indent("(c) " & Kapsis.pkg.author & " | " & Kapsis.pkg.license & " License", 2)
    # todo author url from nimble file
    add output[0][0], indent("\nBuild Version: " & Kapsis.pkg.version & "\e[0m\n", 2)
  if not showSubCommands:
    for id, cmd in Kapsis.commands:
      case cmd.ctype
      of ctCmd:   # write command
        if not cmd.isSubCmd and showExtras == false:
          add output, ("", "")
          add cmdlen, id.len
          cmd.outputCommand(output, cmdlen, showExtras)
        elif showExtras:
          add output, ("", "")
          add cmdlen, id.len
          cmd.outputCommand(output, cmdlen, showExtras)
      of ctCmdSep: # write command separators
        add output, ("", "")
        add output[^1][0], "\e[1m" & cmd.label & "\e[0m"
      of ctCmdDir:
        add output, ("", "\e[90m" & cmd.desc & "\e[0m")
        add cmdlen, cmd.idDir.len + 4
        add output[^1][0], cmd.idDir
        let icon = 
          if showExtras: "▲"
          else: "▼"
        add output[^1][0], indent("\e[36m" & icon & "\e[0m", 1)
      else: discard
  let orderedCmdLen = sorted(cmdlen, system.cmp[int], order = SortOrder.Descending)
  let longestCmd = orderedCmdLen[0]
  var i = 0
  var plain: string
  for x in output:
    if x[1].len > 0:
      display(x[0] & indent(x[1], (longestCmd - cmdlen[i]) + 10))
      inc i
    else:
      display(x[0])

proc addCommand*(k: KapsisCli, key: string, cmd: KapsisCommand) =
  ## Add a new command line
  k.commands[key] = cmd

proc addCommand*(k: KapsisCli, parent, key: string, cmd: KapsisCommand) =
  if k.commands[parent].list == nil:
    k.commands[parent].list = newOrderedTable[string, KapsisCommand]()
  cmd.isSubCmd = true
  k.commands[parent].list[key] = cmd
  k.commands[key] = cmd

proc prefix(id: sink string, kind: CmdLineKind): string =
  case kind
  of cmdShortOption:
    result = "-"
  of cmdLongOption:
    result = "--"
  else: discard
  add result, id

proc addArg*(cmd: KapsisCommand, id: string, kind: CmdLineKind,
      datatype: KapsisValueType, argtype = KapsisArgType.katArg,
      isOpt = false) =
  ## Create a new argument
  cmd.args[id.prefix(kind)] = KapsisArgument(
    lkind: kind,
    datatype: datatype,
    argtype: argtype,
    isOptional: isOpt
  )
  if kind == cmdArgument:
    cmd.argsIndex.add((kind, id))

proc addVariant*(cmd: KapsisCommand, id: string,
    argVariant: openarray[string]) =
  ## Create a new argument
  cmd.args[id] = KapsisArgument(
    lkind: CmdLineKind.cmdArgument,
    datatype: KapsisValueType.vtString,
    argtype: KapsisArgType.katVariant,
    argVariant: toSeq(argVariant)
  )
  cmd.argsIndex.add((cmd.args[id].lkind, id))

proc renameCallback(x: string): string {.compileTime.} =
  x.replace("getV", "get")
expandGetters(renameCallback)

#
# Compile-time functions
#
proc addkv(cmdobj: NimNode, key: string, val: NimNode) {.compileTime.} =
  add cmdobj, nnkExprColonExpr.newTree(ident(key), val)

template parseArgument(node: NimNode, isOpt: bool) {.dirty.} =
  try:
    let vtype = parseEnum[KapsisValueType](node[0].strVal)
    var
      argName: string
      argType = vtype.symbolName
      cmdArgType: string
    case node[1].kind
    of nnkAccQuoted:
      argName = node[1][0].strVal
      cmdArgType = "cmdArgument"
    of nnkPrefix:
      if node[1][0].eqIdent("--"):
        argName = node[1][1].strVal
        cmdArgType = "cmdLongOption"
      elif node[1][0].eqIdent("-"):
        argName = node[1][1].strVal
        cmdArgType = "cmdShortOption"
      else:
        error("Invalid flag, expected --xyz or -x")
    of nnkIdent:
      argName = node[1].strVal
      cmdArgType = "cmdArgument"
    else:
      error("Invalid argument " & $(node[1].kind))
    add result,
      newCall(
        ident "addArg",
        cmdx,
        newLit $(argName),
        ident cmdArgType,
        ident argType,
        ident "katArg",
        newLit isOpt
      )
  except:
    error("Unknown type " & node[0].strVal & ". Use one of: " & KapsisValueType.toSeq().join(", "), x[0])

proc parse(cmd: NimNode, cmdParent: NimNode = nil): NimNode {.compileTime.} =
  let id = cmd[0]
  result = newStmtList()
  var
    cmdx = gensym(nskLet, "cmdx")
    cmdobj = newNimNode(nnkObjConstr).add(
      ident("KapsisCommand")
    )
  var cmdType: KapsisCommandType
  var callbackIdent = id.strVal & "Command"
  var subCommands: seq[NimNode]
  add result, newLetStmt(cmdx, cmdObj)
  for x in cmd[1..^1]:
    case x.kind
    of nnkAccQuoted:
      echo x
    of nnkCall, nnkCommand:
      parseArgument(x, false)
    of nnkTupleConstr:
      # parse pairs of short/long flags
      if x.len == 2:
        for t in x:
          var flagtype: string
          if t[0][0].eqIdent("--"):
            flagtype = "cmdLongOption"
          elif t[0][0].eqIdent("-"):
            flagtype = "cmdShortOption"
          let vtype = parseEnum[KapsisValueType]($t[1])
          add result,
            newCall(
              ident "addArg",
              cmdx,
              newLit $(t[0][1]),
              ident flagtype,
              ident vtype.symbolName
            )
      else:
        error("Use tuple to group pairs of short and long flags")
    of nnkBracket:
      # parse variant-based arguments
      # salt|peper|curry
      var vararg = newNimNode(nnkBracket)
      for i in x:
        expectKind(i, nnkIdent)
        vararg.add(newLit(i.strVal))
      var somegen = genSym(nskVar, "variant")
      add result,
        newCall(
          ident "addVariant",
          cmdx,
          newLit(somegen.repr),
          vararg
        )
    of nnkStmtList:
      for z in x:
        case z.kind
        of nnkCommentStmt:
          cmdobj.addkv("desc", newLit(z.strVal))
        of nnkPrefix:
          # parse argument helper prefixed with `?`
          if z[0].eqIdent("?"):
            let argName = z[1..^1][0][0]
            let argDesc = z[1..^1][0][1]
            # todo
        of nnkCall, nnkCommand:
          cmdType = ctCmdDir
          add subCommands, parse(z, id)
        else:
          discard # error?
    of nnkPrefix:
      if x[0].eqIdent("-"):
        # handle short flags  
        expectKind(x[1], nnkIdent)
        if x[1].strVal.len == 1:
          echo "ok"
        else:
          error("Invalid short flag `-" & $(x[1]) & "`")
      elif x[0].eqIdent("?"):
        # parse optional arguments
        parseArgument(x[1], true)
    else: discard # error?
  cmdobj.addkv("ctype", ident symbolName(cmdType))
  case cmdType
  of ctCmd:
    cmdobj.addkv("id", newLit(id.strVal))
    let cmdIdentifier =
      if cmdParent != nil:
        cmdParent.strVal & "." & id.strVal
      else: id.strVal
    # add the runnable callback
    cmdobj.addkv("callback", ident(callbackIdent))
    if cmdParent == nil:
      add result,
        newCall(
          ident "addCommand",
          ident "Kapsis",
          newLit cmdIdentifier,
          cmdx
        )
    else:
      add result,
        newCall(
          ident "addCommand",
          ident "Kapsis",
          newLit cmdParent.strVal,
          newLit cmdIdentifier,
          cmdx
        )
  of ctCmdDir:
    cmdobj.addkv("idDir", newLit(id.strVal))
    add result,
      newCall(
        ident "addCommand",
        ident "Kapsis",
        newLit id.strVal,
        cmdx,
      )
    for subCommand in subCommands:
      add result, subCommand
  else: discard

proc sep(label: NimNode): NimNode {.compileTime.} =
  var
    cmdx = gensym(nskLet, "sep")
    obj = newNimNode(nnkObjConstr).add(
      ident("KapsisCommand")
    )
  obj.addkv("ctype", ident "ctCmdSep")
  obj.addkv("label", newLit(label.strVal))
  result = newStmtList()
  add result, newLetStmt(cmdx, obj)
  add result, newCall(
    ident "addCommand",
    ident "Kapsis",
    newLit($(toMD5(label.strVal))),
    cmdx
  )

template collectPackageInfo {.dirty.} =
  let path = os.normalizedPath(getProjectPath() / "..")
  let info = staticExec("nimble dump " & path & " --json").strip()
  var
    appVersion: string
    appDescription: string
    appAuthor: string
    appLicense: string
  if info.len > 0:
    var pkginfo = info.parseJSON()
    appVersion = pkginfo["version"].getStr
    appDescription = pkginfo["desc"].getStr
    appAuthor = pkginfo["author"].getStr
    appLicense = pkginfo["license"].getStr

proc isBool*(v: string): bool =
  result = v in ["true", "false"]

proc isFloat*(v: string): bool =
  try:
    discard parseFloat(v)
    return true
  except ValueError:
    discard

proc isInt*(v: string): bool =
  try:
    discard parseInt(v)
    return true
  except ValueError:
    discard

template collectValues(values: var ValuesTable,
    argName, val: string, arg: KapsisArgument) =
  block:
    var hasError: bool
    case arg.datatype
    of vtString:
      case arg.argtype
      of katVariant:
        if likely(val in arg.argVariant):
          values[argName] =
            Value(vt: vtString, vStr: val)
        else:
          hasError = true
      else:
        if val.isBool or val.isInt or val.isFloat:
          hasError = true
        elif val.len > 0:
          if val[0] in IdentStartChars:
            values[argName] =
              Value(vt: vtString, vStr: val)
          else:
            hasError = true
        else:
          hasError = true
    of vtBool:
      try:
        values[argName] =
          Value(vt: vtBool, vBool: parseBool(val))
      except ValueError:
        hasError = true
    of vtInt:
      try:
        values[argName] =
          Value(vt: vtInt, vInt: parseInt(val))
      except ValueError:
        hasError = true
    of vtFloat:
      try:
        values[argName] =
          Value(vt: vtFloat, vFloat: parseFloat(val))
      except ValueError:
        hasError = true
    of vtFile:
      if fileExists(val):
        values[argName] = Value(vt: vtFile,
          vFile: KapsisPath(file: val.getFileInfo, path: val))
      else:
        hasError = true
    of vtPath:
      values[argName] = Value(vt: vtPath,
        vPath: KapsisPath(file: val.getFileInfo, path: val))
    of vtFilename:
      if val.isValidFilename:
        values[argName] = Value(vt: vtFilename, vFilename: val)
      else:
        hasError = true
    of vtDir:
      if dirExists(val):
        values[argName] = Value(vt: vtDir,
          vDir: KapsisPath(file: val.getFileInfo, path: val))
      else:
        hasError = true
    of vtMilliseconds:
      try:
        let v = parseInt(val)
        values[argName] = Value(vt: vtMilliseconds,
          vMilliseconds: initDuration(milliseconds = v))
      except ValueError:
        hasError = true
    of vtSeconds:
      try:
        let v = parseInt(val)
        values[argName] = Value(vt: vtSeconds,
          vSeconds: initDuration(seconds = v))
      except ValueError:
        hasError = true
    of vtHours:
      try:
        let v = parseInt(val)
        values[argName] = Value(vt: vtHours,
          vHours: initDuration(hours = v))
      except ValueError:
        hasError = true
      # todo other cases
    else: discard
    if hasError:
      printError(typeMismatch, argName, $arg.datatype)

var kapsisSettings {.compileTime.} = KapsisSettings()
macro settings*(mainCommand: static string) =
  kapsisSettings.mainCommandId = mainCommand

macro commands*(registeredCommands: untyped, extras: untyped = nil) =
  collectPackageInfo()
  result = newNimNode(nnkBlockStmt)
  add result, newEmptyNode()
  var blockStmt = newStmtList()
  for cmd in registeredCommands:
    case cmd.kind
    of nnkCommand:
      add blockStmt, parse(cmd)
    of nnkPrefix:
      if cmd[0].eqIdent("--"):
        add blockStmt, sep(cmd[1])
    of nnkCall:
      # parse commands without arguments/options
      add blockStmt, parse(cmd)
    else: discard # error?
  
  # set meta information
  add blockStmt, quote do:
    Kapsis.pkg = (`appDescription`, `appVersion`, `appAuthor`, `appLicense`)
  
  # init kapsis runtime 
  add blockStmt, quote do:
    if Kapsis.commands.hasKey(`kapsisSettings`.mainCommandId):
      # set custom settings
      # todo
      Kapsis.mainCommand = Kapsis.commands[`kapsisSettings`.mainCommandId]
    var
      p = quoteShellCommand(commandLineParams()).initOptParser
      id: KapsisInput
      input = p.getopt.toSeq()
      defaultCommand = Kapsis.mainCommand != nil
    if input.len == 0:
      printUsage()
      QuitSuccess.quit
    if Kapsis.commands.hasKey(input[0].key) == false and defaultCommand:
      id = (cmdArgument, Kapsis.mainCommand.id, "")
    else:
      id = input[0]
      input.delete(0)
    # flags don't have a fixed position,
    # they can be specified at any position
    var flags: seq[KapsisInput]
    var values = ValuesTable()
    case id.kind
    of cmdArgument:
      if likely(Kapsis.commands.hasKey(id.key)):
        let cmd: KapsisCommand = Kapsis.commands[id.key]
        var i = 0
        while i <= input.high:
          case input[i].kind
          of cmdLongOption, cmdShortOption:
            if input[i].key in ["help", "h"]:
              # print helpers of a specific command
              printUsage(showExtras=true, showCommand=id.key)
              QuitSuccess.quit
            else:
              let key = prefix(input[i].key, input[i].kind)
              if likely cmd.args.hasKey(key):
                let arg = cmd.args[key]
                # passing a `vtBool` flag without a specific
                # a value is interpreted as `true`
                if arg.datatype == vtBool and input[i].val.len == 0:
                  input[i].val = "true"
                values.collectValues(key, input[i].val, arg)
                input.delete(i)
                inc i
              else:
                printError(unknownOption, key)
                QuitFailure.quit
          else:
            inc i
        case cmd.ctype
        of ctCmd:
          let index = cmd.argsIndex
          for i in 0..index.high:
            if index[i][0] in {cmdLongOption, cmdShortOption}:
              continue
            try:
              if input[i].kind == index[i][0]:
                if cmd.args.hasKey(index[i][1]):
                  let arg = cmd.args[index[i][1]]
                  let val = input[i].key
                  values.collectValues(index[i][1], val, arg)
              else:
                printError(unexpectedOption, input[i].key)
            except IndexDefect:
              let arg = cmd.args[index[i][1]]
              if arg.isOptional: continue
              printUsage()
              printError(missingArgument, index[i][1], $(arg.datatype))
              QuitFailure.quit
          # run command's callback
          cmd.callback(values.addr)
          # use either fail() or ok() in your command's
          # callback, otherwise this is the default exit code
          quit(QuitSuccess)
        of ctCmdDir:
          # directories don't have a callback to run
          # instead, will list the available subcommands.
          printUsage(false, cmd.idDir, true)
        else: discard
      else: printError(unknownCommand, id.key)
    of cmdLongOption, cmdShortOption:
      # print usage including argument types.
      # -v/--version prints the current version
      # of the application that is automatically
      # retrieved from your .nimble file
      case id.key
      of "help", "h":     printUsage(showExtras = true)
      of "version", "v":  display(Kapsis.pkg.version)
      else:               printError(unknownOption, id.key)
    else: discard
  add result, blockStmt
  # echo result.repr
