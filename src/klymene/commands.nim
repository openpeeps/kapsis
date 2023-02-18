# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
#       
#       https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

{.warning[Spacing]: off.}

import pkg/pkginfo
import std/[macros, tables, terminal, sets, sequtils]
import std/strutils

from std/os import commandLineParams, sleep
from std/algorithm import sorted, SortOrder

export tables

type
  KlymeneErrors* = enum
    MaximumDepthSubCommand = "Maximum subcommand depth reached (3 levels)"
    ParentCommandNotFound = "Could not find a command id \"$1\""
    ConflictCommandName = "Command name \"$1\" already exists"

  ParameterType* = enum
    Key, Variant, LongFlag, ShortFlag

  ParamTuple* = tuple[ptype: ParameterType, pid, help: string]

  Parameter* = ref object
    case ptype*: ParameterType
    of Key:
      key: string
      vStr*: string
    of Variant:
      variant: seq[string]
      vTuple*: string
    of LongFlag:
      flag: string
      vLong*: bool
    of ShortFlag:
      sflag: string
      vShort*: bool
    help*: string

  Values* = ptr OrderedTable[string, Parameter]

  CommandType* = enum
    typeCommandLine
    typeCommentLine
    typeSubCommandLine

  Callback* = proc(v: Values) {.nimcall.}
  Command* = object
    name*: string
      # Holds the raw command name
    case commandType: CommandType
    of typeCommandLine, typeSubCommandLine:
      commandName: string
      callbackName*: string
      callback: Callback
      description: string
      args: OrderedTable[string, Parameter]
      index: seq[ParamTuple]
        # A seq that reflects the order of your parameters 
    else: discard # ignore comment lines

  Klymene* = ref object
    indent*: int8
      # Used to indent & align comments (default 25 spaces)
    app_name*: string
      ## The application name
    commands*: OrderedTableRef[string, Command]
      ## Holds a parsable table with `Command` instances
    description*: string
    version*: string
    invalidArg*: string
    error*: string
    extras*: string
      # when suffixed with `-h` `--help`
      # holds temporary extra info related to
      # a command flags/params

  KlymeneDefect* = object of CatchableError
  SyntaxError* = object of CatchableError

const NewLine = "\n"
let
  TokenSeparator {.compileTime.} = "---"
  InvalidVariantWithFlags {.compileTime.} = "Variant parameters cannot contain flags"
  InvalidCommandDefinition {.compileTime.} = "Invalid command definition"

#
# Runtime API
#

proc init[K: typedesc[Klymene]](cli: K): Klymene =
  ## Initialize an instance of Klymene
  result = cli()

proc hasCommand(cli: Klymene, id: string): bool = 
  ## Determine if command exists by id
  result = cli.commands.hasKey(id)

proc getCommand(cli: Klymene, id: string): Command =
  ## Return a Command instance based on given `id`
  result = cli.commands[id]

proc startsWith(cli: Klymene, prefix: string): tuple[status: bool, commands: seq[string]] =
  ## Determine if there any commands that match given prefix.
  if prefix.contains("."):
    var prefixes = prefix.split(".")
    for cmdId in keys(cli.commands):
      if cmdId.startsWith(prefixes[0]):
        # check if there are any commands to add in highlights
        result.commands.add cmdId
  else:      
    for cmdId in keys(cli.commands):
      if cmdId.startsWith(prefix):
        result.commands.add(cmdId)
  result.status = result.commands.len != 0

#
# Command API
# 

proc expectParams(command: Command): bool =
  ## Determine if a command expect any parameters
  result = command.args.len != 0

#
# Print usage
#
proc style(str: string): string {.inline.} =
  result = "\e[90m" & str & "\e[0m"

proc printAppIndex(cli: Klymene, highlights: seq[string], showExtras, showVersion, showUsage: bool) =
  ## Print index with available commands, flags and parameters
  if showVersion: 
    echo cli.version
    return
  if not showUsage and cli.extras.len != 0:
    stdout.write(cli.extras & "\n")
    return
  var
    commandsLen: seq[int]
    index: seq[
      tuple[
        command, description: string,
        commandLen: int,
        commandType: CommandType
      ]
    ]

  for id, cmd in pairs(cli.commands):
    if cmd.commandType == typeCommentLine:
      index.add (cmd.name, "", 0, typeCommentLine)
      continue
    var
      i = 0
      strCommand: string
      baseIndent = 2
    let paramsLen = cmd.args.len
    add strCommand, cmd.commandName
    commandsLen.add strCommand.len
    for paramKey, parameter in pairs(cmd.args):
      case parameter.ptype:
      of Variant:     # `Variant` expose a group of params as a|b|c|d
        if i == 0:
          add strCommand, indent(paramKey, 1)
        else:
          add strCommand, paramKey
        inc(commandsLen[^1], paramKey.len)
        if (i + 1) != paramsLen:
          # add pipe separator for variant-based parameters
          add strCommand, indent(style "|", 0)
        inc commandsLen[^1]
      of Key:         # `Key` params can handle dynamic strings
        add strCommand, indent("<" & "\e[0m" & paramKey & ">", 1)
        inc(commandsLen[^1], paramKey.len + 3) # plus `<` and `>` and 1 space
      of ShortFlag:   # `ShortFlag` are optionals. Always prefixed with a single `-`
        add strCommand, indent("-" & paramKey, 1)
        inc(commandsLen[^1], paramKey.len + 2) # plus `-` and 1 space
      of LongFlag:    # `LongFlag` are optionals. Always prefixed with double `--`
        add strCommand, indent("--" & paramKey, 1)
        inc(commandsLen[^1], paramKey.len + 3) # plus `--` and 1 space
      inc i

    index.add (
      strCommand,
      cmd.description,
      commandsLen[^1],
      cmd.commandType
    )

  # Order commands by length 
  let
    orderedCmds = sorted(commandsLen, system.cmp[int], order = SortOrder.Descending)
    baseCmdIndent = orderedCmds[0]
  var usageOutput: string
  if cli.description.len != 0 and showExtras:
    # prepend extra information when pressing `-h` or `--help`
    # infos about the author, app and copyright notes.
    add usageOutput, "\e[90m" & cli.description & "\e[0m"

  if cli.error.len != 0:
    stdout.write(cli.error & "\n\n")
  elif cli.invalidArg.len != 0:
    stdout.write("Unknown argument \"$1\"\n\n" % [cli.invalidArg])
  elif cli.extras.len != 0:
    stdout.write(cli.extras & "\n\n")

  for k, i in index.mpairs:
    if i.commandType == typeCommentLine:
      if k != 0:
        add usageOutput, NewLine
      add usageOutput, i.command
      add usageOutput, NewLine
      continue

    if i.command in highlights:
      i.command = "\e[97;92m" & i.command & "\e[0m"
    var baseIndent = 10 + (baseCmdIndent - i.commandLen)
    if i.commandType == typeSubCommandLine:
      # indent sub commands by 2 spaces
      baseIndent = baseIndent - 2
      add usageOutput, indent(i.command, 2)
    else:
      add usageOutput, indent(i.command, 2)
    add usageOutput, indent("\e[90m" & i.description & "\e[0m", baseIndent)
    add usageOutput, NewLine
  stdout.write usageOutput

proc quitApp(cli: Klymene, shouldQuit: bool, showUsage = true,
      highlights: seq[string] = @[], showExtras, showVersion = false) =
  ## Quit from current state and print the application index
  if shouldQuit:
    cli.printAppIndex(highlights, showExtras, showVersion, showUsage)
    quit()

proc printUsage*(cli: Klymene): string =
  ## Parse and print usage based on given command line parameters
  var inputArgs: seq[string] = commandLineParams()
  quitApp(cli, inputArgs.len == 0) # quit & prompt usage if missing args
  let inputCmd = inputArgs[0]
  if not cli.hasCommand inputCmd:
    if inputCmd in ["-h", "--help"]:
      # Quit and prompt usage with `showExtras`
      # for displaying extra comments and options
      quitApp(cli, true, showExtras = true)
    elif inputCmd in ["-v", "--version"]:
      quitApp(cli, true, showVersion = true)

    let suggested = cli.startsWith inputCmd
    if suggested.status == true:  # quit and highlight possible matches
      quitApp(cli, true, highlights = suggested.commands)
    else: quitApp(cli, true)  # quit and prompt index
  inputArgs.delete(0) # delete command name from current seq

  var command: Command = cli.getCommand(inputCmd)
  if command.expectParams():
    var gotVariant: bool             # prevent multiple variants at once
    var mainInputArg: string
    if inputArgs.len != 0:
      mainInputArg = inputArgs[0]

    let indexlen = command.index.len
    for i in 0 .. inputArgs.high:
      var p: string
      if inputArgs[i].startsWith("--"):   # get long flags
        p = inputArgs[i][2..^1]
      elif inputArgs[i][0] == '-':        # get short flags
        p = inputArgs[i][1..^1]
      else:                           # get variant or custom param
        p = inputArgs[i]

      if command.args.hasKey(p):
        case command.args[p].ptype:
        of Variant:
          if gotVariant:
            cli.error = "Choose one of the options"
            quitApp(cli, shouldQuit = true, showUsage = false, highlights = @[inputcmd])
          command.args[p].vTuple = p
          gotVariant = true
        of Key:
          command.args[p].vStr = p
        of ShortFlag:
          command.args[p].vShort = true
        of LongFlag:
          command.args[p].vLong = true
      else:
        if indexlen >= i:
          if command.index[i].ptype == Key:
            command.args[command.index[i].pid].vStr = p
        elif p in ["h", "help"] and command.args.hasKey(mainInputArg):
          # Quit, prompt usage and highlight all possible
          # commands that match with given input (if any)
          cli.extras = command.args[mainInputArg].help
          quitApp(cli, shouldQuit = true, showUsage = false)
        else:
          cli.invalidArg = p
          quitApp(cli, true, highlights = @[inputCmd])
  else:
    quitApp(cli, inputArgs.len != 0) # quit when a command does not support extra args
    command = cli.commands[inputCmd]
  result = command.callbackName

proc addSeparator*(cli: Klymene, id: string, key: int) =
  ## Add a new command separator, with or without a label
  let sepId = id & "__" & $key
  var label = if id.len != 0: "\e[1m" & id  & ":\e[0m" else: id
  cli.commands[sepId] = Command(commandType: typeCommentLine, name: label)

proc addDescription*(cli: Klymene, desc: string) =
  cli.description &= desc

proc addVersion*(cli: Klymene, vers: string) =
  ## Use `.nimble` file to retrieve the app version
  ## and show in Usage when `-v` or `--version`
  cli.version = vers

proc addCommand*(cli: Klymene, id, cmdId, desc: string,
                  args: seq[ParamTuple], callbackIdent: string,
                  isSubCommand: bool, callback: Callback) =
  if cli.commands.hasKey(id):
    raise newException(KlymeneDefect, $ConflictCommandName % [id])
  if isSubCommand:    
    cli.commands[id] = Command(commandType: typeSubCommandLine)
  else:
    cli.commands[id] = Command(commandType: typeCommandLine)
  cli.commands[id].name = id
  cli.commands[id].commandName = cmdId
  cli.commands[id].callbackName = callbackIdent
  cli.commands[id].callback = callback
  cli.commands[id].description = desc
  cli.commands[id].index = args

  if args.len != 0:
    var
      strCounter = 0      # holds params length
      strCommand: string
      hasDelimiter: bool
      countDelimiters: int8
    for k, param in pairs(args):
      if cli.commands[id].args.hasKey(param.pid):
        raise newException(KlymeneDefect, "Duplicate parameter name for \"$1\"" % [param.pid])
      cli.commands[id].args[param.pid] = Parameter(ptype: param.ptype)
      case param.ptype:
      of Variant:
        # `Variant` expose a group of params as a|b|c|d
        cli.commands[id].args[param.pid].variant.add(param.pid)
      of Key:
        # `Key` params can handle dynamic strings
        cli.commands[id].args[param.pid].key = param.pid
      of ShortFlag:
        # `ShortFlag` are optionals. Always prefixed with a single `-`
        cli.commands[id].args[param.pid].sflag = param.pid
      of LongFlag:
        # `LongFlag` are optionals. Always prefixed with double `--`
        cli.commands[id].args[param.pid].flag = param.pid
      if param.help.len != 0:
        cli.commands[id].args[param.pid].help = param.help

#
# Compile time API
#
proc `%`(i: string): NimNode =
  result = ident(i)

macro App*(body) =
  result = newStmtList()
  result.add newVarStmt(
    ident "cli",
    newCall(ident "Klymene")
  )
  result.add(
    newAssignment(
      newDotExpr(
        ident "cli",
        ident "commands"
      ),
      newCall(
        nnkBracketExpr.newTree(
          ident "newOrderedTable",
          ident "string",
          ident "Command"
        )
      )
    )
  )

  result.add body

macro settings*(opts) =
  discard

macro about*(info) =
  ## Macro for adding info and other comments above usage commands.
  ## Informations provided via `about` macro will be shown only
  ## when user press `app -h` or `app --help`
  info.expectKind nnkStmtList
  result = newStmtList()

  for i in info:
    if i.kind == nnkStrLit:
      result.add quote do:
        cli.addDescription(`i` & NewLine)
    elif i.kind == nnkCommand:
      if i[0].kind == nnkStrLit:
        i[1].expectKind nnkIntLit
        let typeCommentLine = i[0]
        let size = i[1]
        result.add quote do:
          cli.addDescription(indent(`typeCommentLine`, `size`) & NewLine)
  let currentAppVersion = $pkg().getVersion
  result.add quote do:
    cli.addVersion `currentAppVersion`
  result.add quote do:
    cli.addDescription(NewLine)


template handleTupleConstr(x: untyped) =
  for a in x:
    if a.kind == nnkStrLit:
      if a.strVal.startsWith("--"):
        # Variant-type params cannot contain flags
        error(InvalidVariantWithFlags)
      cmdParams.add (ptype: Variant, pid: a.strVal, help: "")
    else: error(InvalidVariantWithFlags)
  var paramHelpers: seq[tuple[k, help: string]]

template handleShortFlag(x: untyped) =
  # handle short flags based on chars
  cmdParams.add (ptype: ShortFlag, pid: $(char(x.intVal)), help: "")

proc addValue(paramName: string, paramDefaultValue: string): NimNode {.compileTime.} =
  let value = nnkObjConstr.newTree(
    % "Value",
    nnkExprColonExpr.newTree(
      % "vType",
      % "LongFlag"
    ),
    nnkExprColonExpr.newTree(
      % "vLong",
      newLit("false")
    )
  )
  result = nnkExprEqExpr.newTree(% paramName, value)

template handleLongFlagOrNamedArg(x: untyped) =
  # handle long flags or static named arguments
  var param = x.strVal
  var paramType = Key
  if x.strVal.startsWith("--"):
    param = param[2..^1]
    paramType = LongFlag
  cmdParams.add (ptype: paramType, pid: param, help: "")

let suffixCommand {.compileTime.} = "Command"

template getCallbackIdent(): untyped =
  # Retrieve a callback identifier name based on command id
  var cbIdent: string
  parentCommands.add(subCommandId)
  if isSubCommand:
    for k, pCommand in pairs(parentCommands):
      var word: string
      for kk, ch in pairs(pCommand):
        if k == 0 and kk == 0:
          word &= ch
        elif kk == 0:
          word &= toUpperAscii(ch)
        else: word &= ch
      cbIdent &= word
    cbIdent &= suffixCommand
  else:
    var i: int
    var strId: string
    let id = newCommandId.strVal
    let idlen = id.len
    while i < idlen:
      if isAlphaAscii(id[i]):
        strId &= id[i]
      elif id[i] in Whitespace + {'.'}:
        inc i # skip and make next char uppercase 
        strId &= toUpperAscii(id[i])
      inc i
    cbIdent = strId & suffixCommand
  cbIdent

proc handleNamedArguments(tk: NimNode, cmdParams: var seq[ParamTuple]) {.compileTime.} =
  # parse typed type arguments
  for arg in tk:
    expectKind arg, nnkIdent
    cmdParams.add((ptype: Key, pid: arg.strVal, help: ""))

macro commands*(lines: untyped) =
  expectKind lines, nnkStmtList
  result = newStmtList()
  result.add(newCommentStmtNode("Register commands"))
  var
    commandsConditional = newNimNode(nnkIfStmt)
    registeredCommands: seq[string]
    isParentCommand: bool
  for k, line in lines.pairs():
    expectKind line, nnkPrefix
    expectKind line[0], nnkIdent

    if line[0].strVal == "---":
      # Handle command separators
      # Separators are declared using `---` token, followed by
      # either a label or an empty string, for example:
      #   --- "A label"
      expectKind line[1], nnkStrLit
      result.add(
        newCall(
          newDotExpr(%"cli", %"addSeparator"),
          line[1],
          newLit k
        )
      )
    elif line[0].strVal == "$":
      # Handle commands and sub commands
      var
        newCommandId: NimNode
        newCommandDesc = newNimNode nnkStrLit
        newCommandParams: seq[ParamTuple]
        isSubCommand: bool
        subCommandId: string
        parentCommands: seq[string]
      # if newCommandId.strVal.contains("."):
      #   subCommandId = true
      if line[1].kind == nnkCommand:
        newCommandId = line[1][0]
      elif line[1].kind == nnkStrLit:
        newCommandId = line[1]
      
      if newCommandId.strVal in registeredCommands:
        error("The command ID already exists")

      # Command Parser
      # parse command arguments, flags and description
      for token in line:
        if token.kind == nnkIdent:
          if token.eqIdent "$":
            continue
        var cmdParams: seq[ParamTuple]
        if token.kind == nnkCommand:
          for tk in token[1 .. ^1]: # ignore command id
            if tk.kind == nnkAccQuoted:
              tk.handleNamedArguments(cmdParams)
            elif tk.kind == nnkCommand:
              for arg in tk:
                if arg.kind == nnkAccQuoted:
                  arg.handleNamedArguments(cmdParams)
                elif arg.kind == nnkTupleConstr:
                  # A\B\C Variant commands using tuple
                  # constructor ("start", "stop", "refresh")
                  handleTupleConstr(arg)
                elif arg.kind == nnkCharLit:
                  handleShortFlag(arg)
                elif arg.kind == nnkStrLit:
                  handleLongFlagOrNamedArg(arg)
            elif tk.kind == nnkTupleConstr:
              # A\B\C Variant commands using tuple
              # constructor ("start", "stop", "refresh")
              handleTupleConstr(tk)
            elif tk.kind == nnkCharLit:
              handleShortFlag(tk)
            elif tk.kind == nnkStrLit:
              handleLongFlagOrNamedArg(tk)
          if cmdParams.len != 0:
            newCommandParams.add cmdParams
        elif token.kind == nnkStmtList:
          for help in token:
            if help[1].kind == nnkStrLit:
              # set general command description
              newCommandDesc = help[1]
            elif help[1].kind == nnkCommand:
              expectKind help[1][0], nnkIdent  # key ident
              expectKind help[1][1], nnkStrLit # key description
              for p in mitems(newCommandParams):
                # find a better way to set helpers
                if eqIdent(help[1][0], p.pid):
                  p.help = help[1][1].strVal
      

      # Store callback of current command in callbacks table
      let
        callbackIdent = getCallbackIdent()
        callbackFunction = newDotExpr(ident callbackIdent, ident "runCommand")
      var
        cmdId = newCommandId
        paramsSeqNode = newTree nnkPrefix
        paramsBracket = newTree nnkBracket
      paramsSeqNode.add ident "@"
      for param in newCommandParams:
        paramsBracket.add(
            nnkTupleConstr.newTree(
              newLit param.ptype,
              newLit param.pid,
              newLit param.help 
            )
          )
      paramsSeqNode.add(paramsBracket)
      let addCommandNode = newTree nnkCall
      if isSubCommand:
        cmdId = ident subCommandId
      addCommandNode.add(
          newDotExpr(
            ident "cli",
            ident "addCommand"
          ),
          newCommandId,
          cmdId,
          newCommandDesc,
          paramsSeqNode,
          newLit callbackIdent,
          newLit isSubCommand,
          callbackFunction
        )
      result.add(addCommandNode)
      # memorize the command id
      registeredCommands.add(newCommandId.strVal)
      # add command to main conditional statement
      commandsConditional.add(
        nnkElifBranch.newTree(
          nnkInfix.newTree(
            % "==",
            % "commandName",
            newLit(callbackIdent)
          ),
          newStmtList(
            newCall(
              newDotExpr(
                newTree(
                  nnkBracketExpr,
                  newDotExpr(ident "cli", ident "commands"),
                  newLit newCommandId.strVal
                ),
                ident "callback",
              ),
                newDotExpr(
                  newDotExpr(
                    newTree(
                      nnkBracketExpr,
                      newDotExpr(ident "cli", ident "commands"),
                      newLit newCommandId.strVal
                    ),
                    ident "args",
                  ),
                  ident "addr"
                )
            )
          )
        )
      )
  # TODO check if `about` macro has been called,
  # otherwise, get description and version from nimble file.
  result.add(
    newLetStmt(
      ident "commandName",
      newCall(newDotExpr(% "cli", % "printUsage"))
    )
  )
  result.add(
    newCommentStmtNode("Conditionals\nHere we'll decide which command to run")
  )
  result.add(commandsConditional)
  when defined debugcli:
    echo result.repr