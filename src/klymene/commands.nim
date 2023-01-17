# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
#       
#       https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

{.warning[Spacing]: off.}

import std/[tables, macros, terminal, sets, sequtils]
import std/strutils

from std/os import commandLineParams, sleep
from std/algorithm import sorted, SortOrder

type
  KlymeneErrors = enum
    MaximumDepthSubCommand = "Maximum subcommand depth reached (3 levels)"
    ParentCommandNotFound = "Could not find a command id \"$1\""
    ConflictCommandName = "Command name \"$1\" already exists"

  ParameterType* = enum
    Key, Variant, LongFlag, ShortFlag

  ParamTuple = tuple[ptype: ParameterType, pid, help: string]

  Parameter* = ref object
    case ptype: ParameterType
    of Key:
      key: string
    of Variant:
      variant: seq[string]
    of LongFlag:
      flag: string
    of ShortFlag:
      sflag: string
    help: string

  Value* = ref object
    value: Parameter

  CommandType* = enum
    CommandLine, CommentLine, SubCommandLine

  Command* = object
    name: string
      # Holds the raw command name
    case commandType: CommandType
    of CommandLine, SubCommandLine:
      commandName: string
        # Holds only the command name
      callbackName: string
        # Holds the callback name
      description: string
        # Command description
      args: OrderedTable[string, Parameter]
        # An `OrderedTable` holding all command arguments
      index: seq[ParamTuple]
        # A seq that reflects the order of your parameters 
    else: discard # ignore comment lines
  
  InputError = ref object
    msg: string

  Klymene* = ref object
    indent: int8
      # Used to indent & align comments (default 25 spaces)
    app_name: string
      ## The application name
    commands: OrderedTable[string, Command]
      ## Holds a parsable table with `Command` instances
    description: string
    appVersion: string
    invalidArg: string
    error: string
    extras: string
      # when suffixed with `-h` `--help`
      # holds temporary extra info related to
      # a command flags/params

  KlymeneDefect = object of CatchableError
  SyntaxError = object of CatchableError

const NewLine = "\n"
let
  TokenSeparator {.compileTime.} = "---"
  InvalidVariantWithFlags {.compileTime.} = "Variant parameters cannot contain flags"
  InvalidCommandDefinition {.compileTime.} = "Invalid command definition"

proc addSeparator*(cli: Klymene, id: string, key: int) =
  ## Add a new command separator, with or without a label
  let sepId = id & "__" & $key
  var label = if id.len != 0: "\e[1m" & id  & ":\e[0m" else: id
  cli.commands[sepId] = Command(commandType: CommentLine, name: label)

proc addDescription*(cli: Klymene, desc: string) =
  cli.description &= desc

proc addCommand*(cli: Klymene, id, cmdId, desc: string,
                  args: seq[ParamTuple], callbackIdent: string,
                  isSubCommand: bool, isSeparator = false) =
  if cli.commands.hasKey(id):
    raise newException(KlymeneDefect, $ConflictCommandName % [id])
  if isSubCommand:    
    cli.commands[id] = Command(commandType: SubCommandLine)
  else:
    cli.commands[id] = Command(commandType: CommandLine)
  cli.commands[id].name = id
  cli.commands[id].commandName = cmdId
  cli.commands[id].callbackName = callbackIdent
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

macro App*(body) =
  result = newStmtList()
  result.add newVarStmt(ident "cli", newCall(ident "Klymene"))
  result.add body

macro about*(info) =
  ## Macro for adding info and other comments above usage commands.
  ## Informations provided via `about` macro will be shown only
  ## when user press `app -h` or `app --help`
  info.expectKind nnkStmtList
  result = newStmtList()
  result.add(
    nnkVarSection.newTree(
      newIdentDefs(ident "appVersion", ident "string")
    ),
  )

  for i in info:
    if i.kind == nnkStrLit:
      result.add quote do:
        cli.addDescription(`i` & NewLine)
    elif i.kind == nnkCommand:
      if i[0].kind == nnkStrLit:
        i[1].expectKind nnkIntLit
        let commentLine = i[0]
        let size = i[1]
        result.add quote do:
          cli.addDescription(indent(`commentLine`, `size`) & NewLine)
      elif i[0].kind == nnkIdent:
        if i[0].eqIdent "version":
          i[1].expectKind nnkStrLit
          let currentAppVersion = i[1].strVal
          result.add quote do:
            appVersion = `currentAppVersion`
  result.add quote do:
    cli.addDescription(NewLine)

include ./private/runtime

template handleTupleConstr(x: untyped) =
  for a in x:
    if a.kind == nnkStrLit:
      if a.strVal.startsWith("--"):
        # Variant-type params cannot contain flags
        error(InvalidVariantWithFlags)
      cmdParams.add (ptype: Variant, pid: a.strVal, help: "")
    else: error(InvalidVariantWithFlags)
  var paramHelpers: seq[tuple[k, help: string]]

template handleFlags(x: untyped) =
  for a in x:
    if a.kind == nnkCharLit:
      # handle short flags based on chars
      cmdParams.add (ptype: ShortFlag, pid: $(char(a.intVal)), help: "")
    elif a.kind == nnkStrLit:
      # handle long flags and parameters
      var param = a.strVal
      var paramType = Key
      if a.strVal.startsWith("--"):
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

proc `%`(i: string): NimNode =
  result = ident(i)

macro commands*(lines: untyped) =
  expectKind lines, nnkStmtList
  result = newStmtList()
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

      # Store callback of current command in callbacks table
      let
        callbackFunction = newStmtList()
        callbackIdent = getCallbackIdent()
  
      callbackFunction.add newDotExpr(
        % callbackIdent,
        % "runCommand"
      )
      commandsConditional.add(
        nnkElifBranch.newTree(
          nnkInfix.newTree(
            % "==",
            % "commandName",
            newLit(callbackIdent)
          ),
          newStmtList(newCall(callbackFunction))
        )
      )

      # Command Parser
      # parse command arguments, flags and description
      for token in line:
        if token.kind == nnkIdent:
          if token.eqIdent "$":
            continue
        var cmdParams: seq[ParamTuple]
        if token.kind == nnkCommand:
          for tk in token:
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
            elif tk.kind == nnkTupleConstr:
              # A\B\C Variant commands using tuple
              # constructor ("start", "stop", "refresh")
              handleTupleConstr(tk)
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
      
      # memorize the command id
      registeredCommands.add(newCommandId.strVal)

      # register a new command
      result.add quote do:
        var cmdId = `newCommandId`
        var isSubCommand: bool
        if `isSubCommand` != 0:
          cmdId = `subCommandId`
          isSubCommand = true
        cli.addCommand(
          `newCommandId`,
          cmdId,
          `newCommandDesc`,
          `newCommandParams`,
          `callbackIdent`,
          isSubCommand = isSubCommand
        )

  result.add(
    newLetStmt(
      % "commandName",
      newCall(
        newDotExpr(
          % "cli",
          % "printUsage"
        )
      )
    ),
    commandsConditional
  )