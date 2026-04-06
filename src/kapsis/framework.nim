# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import std/[macros, tables, strutils, os, json, sequtils,
          parseopt, options, times, macrocache,
          algorithm, wordwrap]

import ./types, ./interactive/prompts

export tables, types, toSeq, CmdLineKind

type
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
    commands: OrderedTableRef[string, Command]
      # A table of commands, where the key is the command name
      # and the value is the Command object

var kapsisPreparedCommands {.compileTime.} = newOrderedTable[string, NimNode]()

template collectPackageInfo {.dirty.} =
  let path = os.normalizedPath(getProjectPath() / "..")
  let info = staticExec("nimble dump " & path & " --json").strip()
  var
    appVersion: string
    appDescription: string
    appAuthor: string
    appLicense: string
  if info.len > 0:
    try:
      var pkginfo = info.parseJSON()
      appVersion = pkginfo["version"].getStr
      appDescription = pkginfo["desc"].getStr
      appAuthor = pkginfo["author"].getStr
      appLicense = pkginfo["license"].getStr
    except:
      discard # ignore errors, we can still run without this info

proc collectMetadata(appNode: var NimNode, stmtNodes: NimNode) {.compileTime.} =
  # parse metadata, the `author`, `version`, `description` and `license`
  # if not provided, will try staticExec `nimble` and get the juice out of it
  # but in some cases the dev can be a savage and just compile the kapsis app
  # without a nimble file, in that case we'll throw a warning that
  # metadata is missing and the app will run with empty metadata fields
  var author, version, description, license: NimNode
  for n in stmtNodes:
    if n.kind == nnkInfix and n[0].eqIdent"author":
      author = n[1]
    elif n.kind == nnkInfix and n[0].eqIdent"version":
      version = n[1]
    elif n.kind == nnkInfix and n[0].eqIdent"description":
      description = n[1]
    elif n.kind == nnkInfix and n[0].eqIdent"license":
      license = n[1]

  if author == nil or version == nil or description == nil or license == nil:
    echo "Warning: Missing metadata fields. Attempting to collect from nimble..."
    collectPackageInfo()
    if author == nil: author = newLit(appAuthor)
    if version == nil: version = newLit(appVersion)
    if description == nil: description = newLit(appDescription)
    if license == nil: license = newLit(appLicense)

  appNode.add(nnkExprColonExpr.newTree(ident"author", author))
  appNode.add(nnkExprColonExpr.newTree(ident"version", version))
  appNode.add(nnkExprColonExpr.newTree(ident"description", description))
  appNode.add(nnkExprColonExpr.newTree(ident"license", license))

proc stripAnsi(s: string): string =
  ## Removes ANSI escape codes from a string for accurate length calculation
  result = ""
  var i = 0
  while i < s.len:
    if s[i] == '\e':
      inc i
      if i < s.len and s[i] == '[':
        inc i
        while i < s.len and s[i] notin {'m', 'K'}:
          inc i
        if i < s.len: inc i
      else:
        # skip unknown escape sequence
        inc i
    else:
      result.add(s[i])
      inc i

proc preparePrintCommand(cmd: Command,
    output: var seq[(string, string, seq[string])], 
    cmdlen: var seq[int]; showTypes, showFlags = false,
    extraIndent = 2) =
  # Prepares a command for printing in the help message,
  # by adding its name, description and arguments to the output
  # sequence, and calculating the command length
  var flags: seq[string]
  case cmd.kind
  of cmdCommand:
    var str = indent(cmd.name, extraIndent)
    for x, arg in cmd.arguments:
      inc cmdlen[^1], 1 # count the whitespace before each argument
      case arg.kind
      of cmdArgument:
        var i = (if arg.isOptional: 4 else: 3)
        inc cmdlen[^1], (arg.name.len + i) # count `<` `arg` `>` includes 1 ws indent
        add str, indent(("\e[90m<$1\e[0m" % [if arg.isOptional: "?" else: ""]), 1)
        add str, arg.name
        if showTypes:
          add str, "\e[36m:" & $arg.dataType & "\e[0m"
          # inc cmdlen[^1], (len($arg.dataType) + 1)
        add str, "\e[90m>\e[0m"
      of cmdLongOption:
        if showFlags:
          add flags, arg.name & "\e[36m:" & $arg.dataType & "\e[0m"
      of cmdShortOption:
        if showFlags:
          add flags, arg.name & "\e[36m:" & $arg.dataType & "\e[0m"
      else: discard
    add output[^1][0], str
    if cmd.arguments.len > 0:
      if not showFlags:
        add output[^1][0], indent("⚑", 1)
        inc cmdlen[^1], 2
      else:
        add output[^1][2], flags
    add output[^1][1], cmd.description
    
  of cmdSeparator:
    add output[^1][0], "\e[1m" & cmd.name & "\e[0m"
  else: discard

proc printUsage(app: Kapsis,
    showExtras = false,
    showTypes = false,
    showFlags = false,
    someSomeCommand: Option[string] = none(string),
    quitProcess = false) =
  # Prints the usage information for the Kapsis application,
  # including the list of commands and their descriptions.
  var output: seq[(string, string, seq[string])] # output lines
  var cmdlen: seq[int]
  
  if showExtras:
    add output, ("", "", @[])
    add output[0][0], "\e[90m" & app.description & "\n"
    add output[0][0], indent("(c) " & app.author & " | " & app.license & " License", 2)
    add output[0][0], indent("\nBuild Version: " & app.version & "\e[0m", 2)
    add output, ("", "", @[])

  if someSomeCommand.isSome():
    # in case we're showing usage for a specific command
    # for id, cmd in app.commands:
    #   var args: seq[string]
    #   for arg in cmd.arguments:
    #     var argStr = ""
    #     if arg.isOptional: argStr.add("?")
    #     argStr.add(arg.name & ":" & $arg.dataType)
    #     args.add(argStr)
    #   output.add((cmd.name, cmd.description, args))
    #   cmdlen.add(cmd.name.len)
    discard
  else:
    # otherwise show usage for all commands
    for id, cmd in app.commands:
      add output, ("", "", @[])
      add cmdlen, cmd.name.len
      preparePrintCommand(cmd, output, cmdlen,
          showTypes = showTypes, showFlags = showFlags)
  var plain: string
  let orderedCmdLen = sorted(cmdlen, system.cmp[int], order = SortOrder.Descending)
  let longestCmd = orderedCmdLen[0] # get longest command length\
  # Now print each command, padding so the comment aligns
  var i = 0
  for x in output:
    if x[1].len > 0:
      # we need to calculate the necessary padding
      # to align the comments, we know the longest command without
      # ansii codes, so we can calculate the padding for each command
      let cmdLineLen = stripAnsi(x[0]).len
      var pad = longestCmd - cmdLineLen + 18 # +2 for spacing
      if showTypes:
        pad -= 2
      let wrapped = wrapWords(x[1], 60)
      let lines = wrapped.splitLines
      for j, line in lines:
        if j == 0:
          display(x[0] & repeat(" ", pad) & "\e[90m" & line & "\e[0m")
        else:
          display(repeat(" ", longestCmd + 16) & "\e[90m" & line & "\e[0m")
      inc i
    else:
      display(x[0])
    if x[2].len > 0 and showExtras:
      var maxFlagLen = 1
      for flag in x[2]:
        let flagLen = stripAnsi(flag).len
        if flagLen > maxFlagLen:
          maxFlagLen = flagLen
      # Print each flag, right-aligned
      for flag in x[2]:
        let flagLen = stripAnsi(flag).len
        let pad = maxFlagLen - flagLen
        display(repeat(' ', pad) & flag, 8)
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
    var kind: CmdLineKind
    case n.kind
    of nnkDotExpr:
      argTypeNode = n[1]
      argNameNode = n[0]
      kind = cmdArgument
    of nnkCommand, nnkCall:
      argTypeNode = n[0]
      argNameNode = n[1]
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
  let userInput = p.getopt.toSeq()
  if userInput.len > 0 == false:
    printUsage(app, showTypes = false, quitProcess = true)
  let input = userInput[0]
  if input.kind == cmdArgument:
    if likely(app.commands.hasKey(input.key)):
      let cmd = app.commands[input.key]
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
    else:
      # if the default command is defined, execute it with the user's 
      # input as arguments
      displayError("Unknown command: " & input.key)
  else:
    # usually this means the user is asking for `-h or --help`, `-v or --version`
    if likely(input.kind == cmdShortOption or input.kind == cmdLongOption):
      if input.key == "h" or input.key == "help":
        # show everything in the help message, including argument types and flags
        printUsage(app, showExtras = true, showTypes = true,
                    showFlags = true, quitProcess = true)
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
      # initialize the command line parser and parse the user's input
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
