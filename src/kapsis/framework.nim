# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import std/[macros, tables, strutils, os, sequtils,
          parseopt, options, times, macrocache,
          algorithm, wordwrap, terminal, json, unicode]

import ./types, ./interactive/prompts, ./plugins

export options
export tables, types, toSeq, CmdLineKind
export plugins

type
  ColoredSegment* = object
    text*: string
    fg*: ForegroundColor
    bright*: bool
    bold*: bool

  CmdArg* = ref object
    ## The CmdArg object represents an argument of a command, it contains
    ## all the information about the argument, such as its name, type
    ## and whether it's optional or not, used for parsing and validation at runtime
    kind*: CmdLineKind
    dataType*: CmdArgValueType
      ## The type of the argument, used for parsing and validation at runtime
    name*: string
      ## The name of the argument, used to reference it in the command's code block
    description*: string
      ## A description of the argument that will be shown in the help message
    isOptional*: bool
      ## When an argument is optional, it means that the user
      ## doesn't have to provide it when executing the command
    choices*: seq[string]
      ## For `any` arguments, the list of allowed values
  
  CommandType* = enum
    ## The type of the command, used for parsing and validation at runtime
    cmdCommand, cmdGroup, cmdSeparator

  Command* = ref object
    ## The Command object represents a command in the CLI application, it contains
    ## all the information about the command, such as its name, description, arguments
    ## and the code block that will be executed when the command is called.
    name: string
    # The name of the command, used to execute it from the CLI
    case kind: CommandType
    of cmdCommand:
      description*: string
        ## A description of the command that will be shown in the help message
      arguments: seq[CmdArg]
        ## A sequence of arguments that the command accepts, used
        ## for parsing and validation at runtime
      callback: proc(v: Values) {.nimcall.}
        # The code block that will be executed when the command is called,
        # it receives a `Values` object that contains the parsed arguments
    else: discard

  Kapsis* = ref object
    author*, version*, license*, description*: string
      # Metadata fields for the application, used in the
      # help message and for informational purposes
    defaultCommand*: Option[string]
      # A one-shot command is a command that will be executed immediately
      # when the application is run, without the user having to type it in,
      # it's useful for running a specific command directly from the CLI
    commands: OrderedTableRef[string, Command]
      # A table of commands, where the key is the command name
      # and the value is the Command object
    pluginsEnabled*: bool
      # When `true`, the application scans for plugin subcommands at startup
    pluginLocalDir*: Option[string]
      # A local directory (relative to the executable, or absolute) where the
      # application creator chooses to look for plugin shared libraries
    pluginHost*: PluginHost
      # The runtime plugin host, populated at startup when plugins are enabled

var kapsisPreparedCommands {.compileTime.} = newOrderedTable[string, NimNode]()

proc findNimbleFile(): string {.compileTime.} =
  ## Searches for a `.nimble` file near the project being compiled
  ## and returns its path, or an empty string if none was found
  let proj = getProjectPath()
  for dir in @[proj, proj / "..", proj / ".." / ".."]:
    let pattern = dir / "*.nimble"
    when defined(windows):
      # `cmd /c dir /b /a-d "<pattern>" 2>nul`
      let matches = staticExec(
        "cmd /" & "c dir /" & "b /a" & "-d \"" & pattern & "\" 2>n" & "ul").strip()
    else:
      let matches = staticExec(
        "ls \"" & dir & "\"/*.nimble 2>/dev/" & "null").strip()
    if matches.len > 0:
      for line in matches.splitLines:
        let f = line.strip()
        if f.len > 0:
          when defined(windows):
            return dir / f
          else:
            return f
  result = ""

proc parseNimbleField(content, field: string): string =
  ## Extracts `field = "value"` from a `.nimble` file content
  for line in content.splitLines:
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed[0] == '#': continue
    let eq = trimmed.find('=')
    if eq < 0: continue
    if trimmed[0..<eq].strip() != field: continue
    var val = trimmed[eq+1..^1].strip()
    if val.len >= 2 and val[0] == '"' and val[^1] == '"':
      val = val[1..^2]
    return val
  result = ""

template collectPackageInfo {.dirty.} =
  var
    appVersion: string
    appDescription: string
    appAuthor: string
    appLicense: string
  let nimblePath = findNimbleFile()
  if nimblePath.len > 0:
    let content = staticRead(nimblePath)
    appAuthor = parseNimbleField(content, "author")
    appVersion = parseNimbleField(content, "version")
    appDescription = parseNimbleField(content, "description")
    appLicense = parseNimbleField(content, "license")

proc metadataFieldValue(n: NimNode, field: string): NimNode =
  ## Returns the value NimNode for a metadata field in the `initKapsis` block,
  ## handling both `author: "x"` (nnkCall) and `author = "x"` (nnkAsgn) syntax.
  ## Returns nil when the statement is not a match.
  case n.kind
  of nnkCall, nnkAsgn, nnkExprColonExpr:
    if n.len >= 2 and n[0].eqIdent(field):
      let val = n[1]
      if val.kind == nnkStmtList and val.len > 0:
        return val[0]
      return val
  else: discard

proc collectMetadata(appNode: var NimNode, stmtNodes: NimNode) {.compileTime.} =
  # parse metadata, the `author`, `version`, `description` and `license`
  # from the `initKapsis` block, and fall back to reading them
  # directly from the package's `.nimble` file
  var author, version, description, license: NimNode
  for n in stmtNodes:
    let a = metadataFieldValue(n, "author")
    if a != nil: author = a
    let v = metadataFieldValue(n, "version")
    if v != nil: version = v
    let d = metadataFieldValue(n, "description")
    if d != nil: description = d
    let l = metadataFieldValue(n, "license")
    if l != nil: license = l

  if author == nil or version == nil or description == nil or license == nil:
    collectPackageInfo()
    if author == nil: author = newLit(appAuthor)
    if version == nil: version = newLit(appVersion)
    if description == nil: description = newLit(appDescription)
    if license == nil: license = newLit(appLicense)

  var missing: seq[string]
  for (field, node) in [("author", author), ("version", version),
      ("description", description), ("license", license)]:
    if node == nil or (node.kind == nnkStrLit and node.strVal.len == 0):
      missing.add field
  if missing.len > 0:
    echo "Warning: kapsis could not find metadata for: " & missing.join(", ") & "."
    echo "  Include a `.nimble` file in your package, or specify the metadata"
    echo "  manually in the `initKapsis` block, e.g.:"
    echo "    initKapsis do:"
    echo "      author: \"Your Name\""
    echo "      version: \"1.0.0\""
    echo "      description: \"Your app description\""
    echo "      license: \"MIT\""

  appNode.add(nnkExprColonExpr.newTree(ident"author", author))
  appNode.add(nnkExprColonExpr.newTree(ident"version", version))
  appNode.add(nnkExprColonExpr.newTree(ident"description", description))
  appNode.add(nnkExprColonExpr.newTree(ident"license", license))

proc renderColored(segments: seq[ColoredSegment]) =
  for seg in segments:
    if seg.fg != fgDefault:
      stdout.setForegroundColor(seg.fg, seg.bright)
    if seg.bold:
      stdout.setStyle({styleBright})
    write(stdout, seg.text)
    stdout.resetAttributes()

proc segmentLen(segments: seq[ColoredSegment]): int =
  for s in segments: result += s.text.len

proc visualLen(segments: seq[ColoredSegment]): int =
  ## Byte length ignores that multibyte chars (e.g. `⚑`) render as a single
  ## column, so this counts runes instead for accurate display-width math
  for s in segments:
    for r in s.text.runes:
      inc result

proc toCommand*(cmd: PluginCommand): Command =
  ## Converts a plugin command into a regular `Command` so it can be rendered by the
  ## usage/help printer. It is never executed through the built-in dispatch path.
  result = Command(
    kind: cmdCommand,
    name: cmd.name,
    description: cmd.description
  )
  for a in cmd.args:
    result.arguments.add CmdArg(
      kind: a.kind,
      dataType: a.datatype,
      name: a.name,
      isOptional: a.isOptional,
      choices: a.choices
    )

proc preparePrintCommand(cmd: Command,
    output: var seq[(seq[ColoredSegment], string, seq[string])],
    cmdlen: var seq[int]; showTypes, showFlags = false,
    extraIndent = 2) =
  var parts: seq[ColoredSegment]
  var flags: seq[string]
  case cmd.kind
  of cmdCommand:
    parts.add ColoredSegment(text: indent(cmd.name, extraIndent), fg: fgDefault)
    for x, arg in cmd.arguments:
      inc cmdlen[^1], 1
      case arg.kind
      of cmdArgument:
        var i = (if arg.isOptional: 4 else: 3)
        inc cmdlen[^1], (arg.name.len + i)
        parts.add ColoredSegment(text: " <", fg: fgBlack, bright: true)
        if arg.isOptional:
          parts.add ColoredSegment(text: "?", fg: fgBlack, bright: true)
        parts.add ColoredSegment(text: arg.name, fg: fgDefault)
        if showTypes:
          var typeStr = ":" & $arg.dataType
          if arg.dataType == ktAny and arg.choices.len > 0:
            typeStr.add "[" & arg.choices.join(",") & "]"
          parts.add ColoredSegment(text: typeStr, fg: fgCyan)
        parts.add ColoredSegment(text: ">", fg: fgBlack, bright: true)
      of cmdLongOption:
        if showFlags:
          var flagStr = arg.name & ":" & $arg.dataType
          if arg.dataType == ktAny and arg.choices.len > 0:
            flagStr.add "[" & arg.choices.join(",") & "]"
          flags.add flagStr
      of cmdShortOption:
        if showFlags:
          var flagStr = arg.name & ":" & $arg.dataType
          if arg.dataType == ktAny and arg.choices.len > 0:
            flagStr.add "[" & arg.choices.join(",") & "]"
          flags.add flagStr
      else: discard
    if cmd.arguments.len > 0:
      if not showFlags:
        parts.add ColoredSegment(text: " ⚑", fg: fgDefault)
        inc cmdlen[^1], 2
      else:
        output[^1][2] = flags
    output[^1][0] = parts
    output[^1][1] = cmd.description

  of cmdSeparator:
    parts.add ColoredSegment(text: cmd.name, bold: true, fg: fgDefault)
    output[^1][0] = parts
  else: discard

proc printUsage(app: Kapsis,
    showExtras = false,
    showTypes = false,
    showFlags = false,
    someSomeCommand: Option[string] = none(string),
    quitProcess = false,
    searchTerm: Option[string] = none(string)) =
  # Prints the usage information for the Kapsis application,
  # including the list of commands and their descriptions.
  var output: seq[(seq[ColoredSegment], string, seq[string])]
  var cmdlen: seq[int]
  var enableFuzzySearch = searchTerm.isSome()
  if showExtras:
    output.add (@[], "", @[])
    output[0][0].add ColoredSegment(text: app.description & "\n", fg: fgBlack, bright: true)
    output[0][0].add ColoredSegment(text: indent("(c) " & app.author & " | " & app.license & " License", 2), fg: fgBlack, bright: true)
    output[0][0].add ColoredSegment(text: indent("\nBuild Version: " & app.version, 2), fg: fgBlack, bright: true)
    output.add (@[], "", @[])

  var haystack: seq[string]
  if someSomeCommand.isSome():
    discard
  else:
    var iterCommands: seq[(string, Command)]
    for id2, cmd2 in app.commands:
      iterCommands.add (id2, cmd2)
    if app.pluginHost != nil:
      for pcId, pcmd in app.pluginHost.commands:
        iterCommands.add (pcId, pcmd.toCommand())
    for (id, cmd) in iterCommands:
      output.add (@[], "", @[])
      add cmdlen, cmd.name.len
      if cmd.kind == cmdCommand:
        haystack.add(cmd.description)
      preparePrintCommand(cmd, output, cmdlen,
          showTypes = showTypes,
          showFlags = showFlags)

  let orderedCmdLen = sorted(cmdlen, cmp[int], order = SortOrder.Descending)
  let longestCmd = orderedCmdLen[0]

  var i = 0
  for x in output:
    var isHighlighted = false
    if x[1].len > 0:
      let plainLen = segmentLen(x[0])
      var pad = longestCmd - plainLen + 8
      let hasFlagIcon = block:
        var found = false
        for s in x[0]:
          if s.text.contains("⚑"): found = true; break
        found
      if showTypes:
        pad += 4
      elif hasFlagIcon:
        pad += 2
      if pad < 1: pad = 1
      let wrapped = wrapWords(x[1], 60)
      let lines = wrapped.splitLines
      let descCol = visualLen(x[0]) + pad
      for j, line in lines:
        if j == 0:
          if isHighlighted:
            stdout.setBackgroundColor(bgYellow)
            stdout.setForegroundColor(fgBlack)
          renderColored(x[0])
          if isHighlighted:
            stdout.resetAttributes()
          write(stdout, repeat(" ", pad))
          stdout.setForegroundColor(fgBlack, bright=true)
          write(stdout, line)
          stdout.resetAttributes()
          write(stdout, "\n")
        else:
          write(stdout, repeat(" ", descCol))
          stdout.setForegroundColor(fgBlack, bright=true)
          write(stdout, line)
          stdout.resetAttributes()
          write(stdout, "\n")
      inc i
    else:
      renderColored(x[0])
      write(stdout, "\n")
    if x[2].len > 0 and showExtras:
      var flagLens: seq[int]
      for f in x[2]: flagLens.add f.len
      let maxFlagLen = flagLens.max
      for idx, flag in x[2]:
        let pad = maxFlagLen - flagLens[idx]
        write(stdout, repeat(' ', pad + 10))
        let colonPos = flag.find(':')
        if colonPos >= 0:
          write(stdout, flag[0..<colonPos])
          stdout.setForegroundColor(fgCyan)
          write(stdout, flag[colonPos..^1])
          stdout.resetAttributes()
        else:
          write(stdout, flag)
        write(stdout, "\n")
  if quitProcess: quit(0)

proc getCallbackName(s: string): NimNode =
  var res: string
  var i = 0
  while i < s.len:
    case s[i]
    of '-', '_', ' ', '.':
      # skip the separator and capitalize the next character
      inc(i)
      if i < s.len:
        res.add(s[i].toUpperAscii)
    of 'a'..'z', 'A'..'Z':
      # valid identifier characters, just continue
      res.add(s[i])
    else: discard
    inc(i)
  result = ident(res & "Command")

proc parseCommand(cmdName: NimNode, cmdArgs: seq[NimNode] = @[],
              cmdSubStmtList: NimNode = newEmptyNode()) {.compileTime.} =
  # Parse a command definition and register it in the `kapsisPreparedCommands` table
  # checking if there are subcommands
  if cmdSubStmtList.len > 0:
    var subCmdNodes = nnkBracket.newTree()
    if cmdSubStmtList[0].kind == nnkCommentStmt:
      let cmdSubStmtList = cmdSubStmtList[1..^1] # remove the comment statement from the list
      if cmdSubStmtList.len > 0:
        for subCmdNode in cmdSubStmtList:
          let subCmdName = ident(cmdName.strVal & "." & subCmdNode[0].strVal)
          if subCmdNode.kind == nnkCommand or subCmdNode.kind == nnkCall or subCmdNode.kind == nnkIdent:
            parseCommand(subCmdName, subCmdNode[1..^2], subCmdNode[^1])
        return
  var
    argNodes = nnkBracket.newTree()
    commandNode = 
      nnkObjConstr.newTree(
        ident("Command"),
        nnkExprColonExpr.newTree(ident"kind", ident("cmdCommand")),
        nnkExprColonExpr.newTree(ident"name", newLit(cmdName.strVal))
      )
  for n in cmdArgs:
    # parse arguments and subcommands
    var isOptional: bool
    var argTypeNode, argNameNode: NimNode
    var argChoices: seq[string]
    var kind: CmdLineKind
    case n.kind
    of nnkDotExpr:
      argTypeNode = n[1]
      argNameNode = n[0]
      kind = cmdArgument
    of nnkCommand, nnkCall:
      argTypeNode = n[0]
      argNameNode = n[1]
      if argTypeNode.eqIdent"any":
        # `any(name = ["a", "b"])` — arg name + allowed choices
        if argNameNode.kind != nnkExprEqExpr:
          error("`any` arguments require a list of choices: any(name = [\"a\", \"b\"])", n)
        for v in argNameNode[1]:
          argChoices.add v.strVal
        argNameNode = argNameNode[0]
      if argNameNode.kind == nnkStrLit and argNameNode.strVal.startsWith("--"):
        # we handle long options like `--verbose` by
        kind = cmdLongOption
      elif argNameNode.kind == nnkStrLit and  argNameNode.strVal.startsWith("-"):
        # we handle short options like `-v` by
        kind = cmdShortOption
        if argNameNode.strVal.len > 2:
          error("Short option names should be a single character", argNameNode)
      else:
        kind = cmdArgument
    of nnkPrefix:
      # when an argument is prefixed with `?` it means it's optional
      if n[0].eqIdent("?"):
        isOptional = true
        if n[1].kind == nnkDotExpr:
          argTypeNode = n[1][1]
          argNameNode = n[1][0]
        elif n[1].kind == nnkCommand:
          argTypeNode = n[1][0]
          argNameNode = n[1][1]
        elif n[1].kind == nnkCall:
          argTypeNode = n[1][0]
          argNameNode = n[1][1]
          if argTypeNode.eqIdent"any":
            # `?any(name = ["a", "b"])`
            if argNameNode.kind != nnkExprEqExpr:
              error("`any` arguments require a list of choices: any(name = [\"a\", \"b\"])", n)
            for v in argNameNode[1]:
              argChoices.add v.strVal
            argNameNode = argNameNode[0]
          if argNameNode.strVal.startsWith("--"):
            kind = cmdLongOption
          elif argNameNode.strVal.startsWith("-"):
            kind = cmdShortOption
            if argNameNode.strVal.len > 2:
              error("Short option names should be a single character", argNameNode)
          else:
            kind = cmdArgument
        else: error("Invalid argument definition", n)
      else: error("Invalid argument definition", n)
    else: discard
    var argType: CmdArgValueType
    try:
      argType = parseEnum[CmdArgValueType](argTypeNode.strVal)
    except ValueError:
      error("Unknown argument type: " & argTypeNode.strVal, argTypeNode)
    
    argNodes.add(
      nnkObjConstr.newTree(
        ident"CmdArg",
        nnkExprColonExpr.newTree(ident"kind", ident($kind)),
        nnkExprColonExpr.newTree(ident"dataType",newLit(argType)),
        nnkExprColonExpr.newTree(ident"name", newLit(argNameNode.strVal)),
        nnkExprColonExpr.newTree(ident"isOptional", newLit(isOptional)),
        nnkExprColonExpr.newTree(ident"choices", newLit(argChoices)),
      )
    )

  # collects the command's description from the comment statement
  if cmdSubStmtList[0].kind == nnkCommentStmt:
    let description = cmdSubStmtList[0].strVal.strip()
    commandNode.add(nnkExprColonExpr.newTree(ident"description", newLit(description)))

  if argNodes.len > 0:
    commandNode.add(
      nnkExprColonExpr.newTree(ident"arguments", 
        nnkPrefix.newTree(ident"@", argNodes)
      ),
    )

  let callbackName = getCallbackName(cmdName.strVal)
  commandNode.add(nnkExprColonExpr.newTree(ident("callback"), callbackName))

  # register the command in the app's commands table
  kapsisPreparedCommands[cmdName.strVal] = commandNode

proc parseCommandInput(app: Kapsis) =
  # Parses the command line arguments and executes the corresponding command
  var p = quoteShellCommand(commandLineParams()).initOptParser
  var userInput = p.getopt.toSeq()
  if userInput.len > 0 == false:
    printUsage(app, showTypes = false, quitProcess = true)
  let input = userInput[0]
  if input.kind == cmdArgument:
    var hasCmd: bool
    var reqCmd: string
    
    if likely(app.commands.hasKey(input.key)):
      hasCmd = true
      reqCmd = input.key
    elif app.defaultCommand.isSome():
      # insert the default command at the beginning of the user input
      hasCmd = true
      reqCmd = app.defaultCommand.get()
      userInput.insert((cmdArgument, reqCmd, ""), 0)

    if hasCmd:
      let cmd = app.commands[reqCmd]
      var i = 1
      var posArgIdx = 0
      var values = ValuesTable()
      while i < userInput.len:
        # we start from 1 because the first element is the command itself
        # we loop through the user's input and collect the values for each argument
        case userInput[i].kind
        of cmdLongOption, cmdShortOption:
          # handle options like `--verbose` or `-v`
          if userInput[i].key in @["help", "h"]:
            # show everything in the help message, including argument types and flags
            printUsage(app, showExtras = true, showTypes = true,
                            showFlags = true, quitProcess = true)
          elif userInput[i].key in @["version", "v"]:
            display(app.version); quit(0)
          else:
            # flags are orderless, so we need to find the corresponding arg def
            # we can optimize this later
            var arg: CmdArg
            let flagName = (if userInput[i].kind == cmdLongOption: "--" else: "-") & userInput[i].key
            for x in cmd.arguments:
              if x.name == flagName and (x.kind in {cmdLongOption, cmdShortOption}):
                arg = x
                break
            if arg != nil:
              let flagValue = userInput[i].val
              if flagValue.len > 0:
                collectValues(values, flagName, flagValue, arg)
              else:
                # for boolean flags, presence means true and absence
                # means false, so we set the value to "true" when the
                # flag is present
                collectValues(values, flagName, "true", arg)
          inc i
        of cmdArgument:
          # Find the next positional argument definition
          while posArgIdx < cmd.arguments.len and cmd.arguments[posArgIdx].kind != cmdArgument:
            inc posArgIdx
          if posArgIdx < cmd.arguments.len:
            let inputValue = userInput[i].key
            let arg = cmd.arguments[posArgIdx]
            collectValues(values, arg.name, inputValue, arg)
            inc posArgIdx
          else:
            # Too many positional arguments provided
            displayError("Unexpected positional argument: " & userInput[i].key)
          inc i
        else:
          inc i

      # after collecting all the values, we need to check
      # if any required arguments are missing
      for arg in cmd.arguments:
        if arg.kind == cmdArgument and not arg.isOptional and not values.hasKey(arg.name):
          printError(missingArgument, arg.name)
        elif arg.kind in {cmdLongOption, cmdShortOption} and not arg.isOptional:
          if not values.hasKey(arg.name):
            printError(missingArgument, arg.name)

      # after collecting all the values, we execute the command's
      # callback and pass the collected values to it
      cmd.callback(addr values)
    elif app.pluginHost != nil and app.pluginHost.commands.hasKey(input.key):
      # route to a subcommand contributed by a plugin shared library
      let res = app.pluginHost.runPluginCommand(input.key)
      if res.hasKey("error"):
        displayError(res["error"].getStr, quitProcess = true)
    else:
      displayError("Unknown command: " & input.key)
  else:
    # usually this means the user is asking for `-h or --help`, `-v or --version`
    if likely(input.kind == cmdShortOption or input.kind == cmdLongOption):
      if input.key == "h" or input.key == "help":
        # show everything in the help message, including argument types and flags
        let fuzzyInput = 
          if input.val.len > 0:
            some(input.val)
          else:
            none(string)
        printUsage(app, showExtras = true, showTypes = true,
                    showFlags = true, quitProcess = true,
                    searchTerm = fuzzyInput)
      elif input.key == "v" or input.key == "version":
        display(app.version)
      else:
        # if the default command is defined, execute it with the user's 
        # input as arguments
        displayError("Unknown option: " & input.key)

macro initKapsis*(stmtNodes: untyped) =
  ## Initializes a Kapsis application by parsing the commands.
  ## 
  ## Kapsis will try to collect metadata from the provided statements, if not provided
  ## it will try to collect it from the `.nimble` file.
  var appNode = nnkObjConstr.newTree(ident"Kapsis")
  appNode.collectMetadata(stmtNodes)

  for stmtNode in stmtNodes[0..^2]:
    case stmtNode.kind
    of nnkCall, nnkCommand:
      if stmtNode[0].eqIdent"defaultCommand":
        if stmtNode.len != 2 or stmtNode[1][0].kind != nnkStrLit:
          error("Invalid defaultCommand definition", stmtNode)
        appNode.add(nnkExprColonExpr.newTree(
          ident"defaultCommand", newCall(ident"some", stmtNode[1][0])))
      elif stmtNode[0].eqIdent"plugins":
        appNode.add(nnkExprColonExpr.newTree(
          ident"pluginsEnabled", newLit(true)))
        var localDir = ""
        if stmtNode.len > 1 and stmtNode[^1].kind in {nnkStmtList, nnkStmtListExpr}:
          for sub in stmtNode[^1]:
            if sub.kind in {nnkExprColonExpr, nnkAsgn, nnkCall} and
                sub.len >= 2 and sub[0].eqIdent("dir"):
              let v = sub[1]
              if v.kind == nnkStrLit:
                localDir = v.strVal
              elif v.kind in {nnkStmtList, nnkStmtListExpr, nnkExprColonExpr} and
                  v.len > 0 and v[0].kind == nnkStrLit:
                localDir = v[0].strVal
        let dirNode =
          if localDir.len > 0: newCall(ident"some", newLit(localDir))
          else: newCall(ident"none", ident"string")
        appNode.add(nnkExprColonExpr.newTree(ident"pluginLocalDir", dirNode))
      elif stmtNode[0].eqIdent"author" or stmtNode[0].eqIdent"version" or
          stmtNode[0].eqIdent"description" or stmtNode[0].eqIdent"license":
        discard # metadata is already handled by `collectMetadata`
      else:
        error("Unknown statement in initKapsis: " & $stmtNode[0], stmtNode)
    else: discard
  
  # parse commands, the `commands` nnkCall should be the
  # last node inside the `stmtNodes` block
  let commandsNode = stmtNodes[^1]
  expectKind(commandsNode, nnkCall)

  if not commandsNode[0].eqIdent"commands":
    error("The last statement in `initKapsis` should be a call to `commands`")

  for cmdNode in commandsNode[1]:
    case cmdNode.kind
    of nnkPrefix:
      # todo handle label separators `--`
      var x = genSym(nskLabel, "separator")
      kapsisPreparedCommands[x.repr] =
        nnkObjConstr.newTree(
          ident("Command"),
          nnkExprColonExpr.newTree(ident"kind", ident("cmdSeparator")),
          nnkExprColonExpr.newTree(ident"name", newLit(cmdNode[1].strVal))
        )
    of nnkCommand:
      # parse a command definition
      parseCommand(cmdNode[0], cmdNode[1..^2], cmdNode[^1])
    of nnkIdent:
      # parse a command without arguments and description
      parseCommand(cmdNode, @[], newEmptyNode())
    of nnkCall:
      # parse a command without arguments
      parseCommand(cmdNode[0], @[], cmdNode[1])
    else:
      error("Invalid command definition", cmdNode)

  var commandsTableNode = nnkTableConstr.newTree()
  for id, preparedCommand in kapsisPreparedCommands:
    commandsTableNode.add(
      nnkExprColonExpr.newTree(newLit(id), preparedCommand)
    )
  
  # add the commands table to the app node
  appNode.add(
    nnkExprColonExpr.newTree(ident"commands",
      newCall(ident"newOrderedTable", commandsTableNode))
  )

  result = newStmtList()
  var kAppVar = genSym(nskVar, "kApp")
  result.add quote do:
    block:
      var `kAppVar` = `appNode`
      # when plugin support is enabled, scan the global and local plugin
      # directories and register any contributed subcommands
      if `kAppVar`.pluginsEnabled:
        `kAppVar`.pluginHost = initPluginHost(
          getAppFilename(),
          (if `kAppVar`.pluginLocalDir.isSome: `kAppVar`.pluginLocalDir.get else: "")
        )
      # initialize the command line parser and parse the user's
      # input
      parseCommandInput(`kAppVar`)
  # echo result.repr

template initCLI*(stmtNodes: untyped) =
  ## Alias for `initKapsis`, you can use either `initKapsis` or `initCLI`
  ## to initialize your Kapsis application
  initKapsis(stmtNodes)

template initCLIApplication*(stmtNodes: untyped) =
  ## Alias for `initKapsis`, you can use either `initKapsis` or
  ## `initCLIApplcation` to initialize your Kapsis application
  initKapsis(stmtNodes)

template initApp*(stmtNodes: untyped) =
  ## Alias for `initKapsis`, you can use either `initKapsis` or `initApp`
  ## to initialize your Kapsis application
  initKapsis(stmtNodes)
