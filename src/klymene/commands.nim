# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
#       
#       https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

{.warning[Spacing]: off.}

import std/[tables, macros, terminal, sets]

from std/sequtils import delete
from std/os import commandLineParams, sleep
from std/algorithm import sorted, SortOrder
from std/strutils import `%`, indent, spaces, join, startsWith, contains, count, split,
                              toUpperAscii, toLowerAscii

type
    KlymeneErrors = enum
        MaximumDepthSubCommand = "Invalid subcommand \"$1\" Maximum depth of a subcommand is by 3 levels."
        ParentCommandNotFound = "Could not find a parent command id \"$1\""
        ConflictCommandName = "Command \"$1\" name already exists"

    ParameterType* = enum
        Key, Variant, LongFlag, ShortFlag

    ParamTuple = tuple[ptype: ParameterType, pid: string]

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
        else: discard # ignore comment lines

    Klymene* = object
        indent: int8
            # Used to indent & align comments (default 25 spaces)
        app_name: string
            ## The application name
        commands: OrderedTable[string, Command]
            ## Holds a parsable table with `Command` instances
        printable: OrderedTable[string, string]
            ## Holds the printable version of your commands
        canPrintExtras: bool
            ## Used to determine if should print extra comments
            ## above the usage commands
        showAppVersion: string
            ## Holds the application version

    KlymeneDefect = object of CatchableError
    SyntaxError = object of CatchableError



const NewLine = "\n"
let
    TokenSeparator {.compileTime.} = "---"
    InvalidVariantWithFlags {.compileTime.} = "Variant parameters cannot contain flags"
    InvalidCommandDefinition {.compileTime.} = "Invalid command definition"

proc init[K: typedesc[Klymene]](cli: K): Klymene =
    ## Initialize an instance of Klymene
    result = cli()

proc hasCommand[K: Klymene](cli: K, id: string): bool = 
    ## Determine if command exists by id
    result = cli.commands.hasKey(id)

proc cmdStartsWith[K: Klymene](cli: var K, id: string): tuple[status: bool, commands: seq[string]] =
    ## Try search for one or more commands based on given prefix.
    ##
    ## This procedure returns a seq[string] of possible
    ## commands matching given prefix.
    for cmdId in keys(cli.commands):
        if cmdId.startsWith(id):
            result.commands.add(cmdId)
    result.status = result.commands.len != 0

proc hasAnyParams[K: Klymene](cli: K, id: string): bool =
    ## Determine if current command requires params
    result = cli.commands[id].args.len != 0

proc hasFlags[C: Command](cmd: C): bool =
    ## Determine if given `Command` has flags
    for k, p in pairs(cmd.args):
        if p.ptype in {ShortFlag, LongFlag}:
            return true

proc commandExists*[K: Klymene](cli: K, key: string): bool =
    result = cli.commands.hasKey(key)

template getValue*[V: Value](val: V): any =
    ## A callable template to retrieve values from a `runCommand` proc
    # proc getValueByType(ptype: ParameterType) =
    #     result = case ptype: ParameterType
    #     of Key:
    #         key: string
    #     of Variant:
    #         variant: seq[string]
    #     of LongFlag:
    #         flag: string
    #     of ShortFlag:
    #         sflag: string

    # getValueByType(val.value)
    ## TODO

proc token(tok: string): string {.inline.} =
    result = "\e[90m" & tok & "\e[0m"

proc printIndex*[K: Klymene](cli: K, highlightKeys: seq[string], showExtras, showVersion: bool) =
    ## Print index with available commands, flags and parameters
    if showVersion: 
        echo cli.showAppVersion
        return

    # A sequence holding the total length of commands (with args and separators)
    var commandsLen: seq[int]
    var index: seq[tuple[command, description: string, delimiters, commandLen: int, commandType: CommandType]]
    # Parse registered commands and prepare for printing
    for id, cmd in pairs(cli.commands):
        if cmd.commandType == CommentLine:
            index.add (cmd.name, "", 0, 0, CommentLine)
            continue
        var
            i = 0
            strCommand: string
            baseIndent = 2
            countDelimiters: int
        let paramsLen = cmd.args.len
        # write the stringified command line, starting
        add strCommand, cmd.commandName
        commandsLen.add(strCommand.len)
        for paramKey, parameter in pairs(cmd.args):
            # Parse command parameters in order to show in print usage
            case parameter.ptype:
            of Variant:     # `Variant` expose a group of params as a|b|c|d
                add strCommand,
                    if i == 0: indent(paramKey, 1) else: paramKey
                inc(commandsLen[^1], paramKey.len)
                if (i + 1) != paramsLen: # add pipe separator for variant-based parameters
                    add strCommand, indent(token "|", 0)
                    inc countDelimiters
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
        
        inc(commandsLen[^1], countDelimiters)
        index.add (strCommand, cmd.description, countDelimiters, commandsLen[^1], cmd.commandType)

    # get highest len from commandsLen
    let baseCmdIndent = sorted(commandsLen, system.cmp[int], order = SortOrder.Descending)[0]
    var usageOutput: string

    if cli.canPrintExtras and showExtras:
        # Show extra information when pressing `-h` or `--help`
        when declared(aboutDescription):
            # if declared, adds a head comment above the commands containing
            # info about the author, a description and copyright notes
            add usageOutput, "\e[90m" & aboutDescription & "\e[0m"

    for k, i in index.mpairs:
        if i.commandType == CommentLine:
            if k != 0:
                add usageOutput, NewLine
            add usageOutput, i.command
            add usageOutput, NewLine
            continue
        if i.command in highlightKeys:
            i.command = "\e[97;92m" & i.command & "\e[0m"
        var baseIndent = 10 + (baseCmdIndent - i.commandLen - i.delimiters)
        if i.commandType == SubCommandLine:
            baseIndent = baseIndent - 2
            add usageOutput, indent(i.command, 2)
        else:
            add usageOutput, i.command
        add usageOutput, indent("\e[90m" & i.description & "\e[0m", baseIndent)
        add usageOutput, NewLine
    echo usageOutput

template quitApp[K: Klymene](cli: K, shouldQuit: bool,
    showUsage = true, highlightKeys: seq[string] = @[], showExtras, showVersion = false): untyped =
    # Template to quit app and print the current commands.
    if shouldQuit:
        if showUsage:
            cli.printIndex(highlightKeys, showExtras, showVersion)
        quit()

proc printUsage*[K: Klymene](cli: var K): string =
    ## Parse and print usage basde on given command line parameters
    var inputArgs: seq[string] = commandLineParams()
    
    quitApp(cli, inputArgs.len == 0)           # quit & prompt usage when missing args
    let inputCmd = inputArgs[0]
    if hasCommand(cli, inputCmd) == false:
        if inputArgs[0] in ["-h", "--help"]:
            # Quit and prompt usage with `showExtras` for displaying extra comments and options
            quitApp(cli, true, showExtras = true)
        elif inputArgs[0] in ["-v", "--version"]:
            quitApp(cli, true, showVersion = declared(appVersion))

        let suggested = cmdStartsWith(cli, inputCmd)
        if suggested.status == true:            # quit and highlight possible matches
            quitApp(cli, true, highlightKeys = suggested.commands)
        else: quitApp(cli, true)                # quit and prompt index
    inputArgs.delete(0)                         # delete command name from current seq

    var command: Command
    if hasAnyParams(cli, inputCmd):
        command = cli.commands[inputCmd]
        for inputArg in inputArgs:
            var p: string
            if inputArg.startsWith("--"):
                p = inputArg[2..^1] # long flag
            elif inputArg[0] == '-':
                p = inputArg[1..^1] # short flag
            else: p = inputArg

            # Quit, prompt usage and highlight
            # the command when provided arguments are not valid
            quitApp(cli, command.args.hasKey(p) == false, highlightKeys = @[inputCmd])

            let parameter = command.args[p]
            case parameter.ptype:
            of Key:
                echo parameter.key
            of Variant:
                echo parameter.variant
            of ShortFlag:
                echo "short flag"
            of LongFlag:
                echo "long flag"
    else:
        quitApp(cli, inputArgs.len != 0) # quit when a command does not support extra args
        command = cli.commands[inputCmd]
    result = command.callbackName

proc add[K: Klymene](cli: var K, id: string, key: int) =
    ## Add a new command separator, with or without a label
    let sepId = id & "__" & $key
    var label = if id.len != 0: "\e[1m" & id  & ":\e[0m" else: id
    cli.commands[sepId] = Command(commandType: CommentLine, name: label)

proc add[K: Klymene](cli: var K, id, cmdId, desc: string, args: seq[ParamTuple], callbackIdent: string, isSubCommand, isSeparator = false) =
    ## Add a new command to current Klymene instance. Commands are registered
    ## automatically from `commands` macro.
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

proc getCommands[K: Klymene](cli: var K): seq[string] {.inline.} =
    for cmdId in keys(cli.commands):
        if cmdId.startsWith("__"): continue
        result.add(cmdId)

macro about*(info: untyped) =
    ## Macro for adding info and other comments above usage commands.
    ## Informations provided via `about` macro will be shown only
    ## when user press `app -h` or `app --help`
    info.expectKind nnkStmtList
    result = newNimNode(nnkStmtList)
    result.add(
        nnkVarSection.newTree(
            newIdentDefs(ident "aboutDescription", ident "string")
        ),
        nnkVarSection.newTree(
            newIdentDefs(ident "appVersion", ident "string")
        ),
    )

    for i in info:
        if i.kind == nnkStrLit:
            result.add quote do:
                add aboutDescription, `i` & NewLine
        elif i.kind == nnkCommand:
            if i[0].kind == nnkStrLit:
                i[1].expectKind nnkIntLit
                let commentLine = i[0]
                let size = i[1]
                result.add quote do:
                    add aboutDescription, indent(`commentLine`, `size`) & NewLine
            elif i[0].kind == nnkIdent:
                if i[0].eqIdent "version":
                    i[1].expectKind nnkStrLit
                    let currentAppVersion = i[1].strVal
                    result.add quote do:
                        appVersion = `currentAppVersion`
        # elif i.kind == nnkCall:
        #     i[0].expectKind nnkIdent
        #     echo i[1].kind
    result.add quote do:
        add aboutDescription, NewLine

macro settings*(generateBashScripts, useSmartHighlight: bool) = 
    ## Macro for changing your Klymene settings
    ## TODO

# template toCamelCase(input: string): string =
#     for i in input:

template getCallbackIdent(): untyped = 
    var commandCallbackIdent: string
    parentCommands.add(subCommandId)
    if isSubCommand:
        for k, pCommand in pairs(parentCommands):
            var word: string
            for kk, charCommand in pairs(pCommand):
                if k == 0 and kk == 0:
                    word &= charCommand
                elif kk == 0:
                    word &= toUpperAscii(charCommand)
                else: word &= charCommand
            commandCallbackIdent &= word
        commandCallbackIdent &= "Command"
    else:
        commandCallbackIdent = newCommandId.strVal & "Command"
    commandCallbackIdent

macro commands*(tks: untyped) =
    ## Macro for creating commands, subcommands
    tks.expectKind nnkStmtList
    
    # Init Klymene
    result = newStmtList(
        newVarStmt(
            ident "cli",
            newCall ident("Klymene")
        )
    )

    # var showDefaultLabel: bool
    var commandsConditional = newNimNode(nnkIfStmt)
    var registeredCommands: seq[string]
    for tkey, tk in pairs(tks):
        tk[0].expectKind nnkIdent
        if tk[0].strVal != "$" and tk[0].strVal != TokenSeparator:
            raise newException(SyntaxError, "Command declaration missing $ prefix.")
        if tk[0].strVal == TokenSeparator:
            # Handle Commands Separators
            # Separators are declared using `---` token, followed by
            # either a label or an empty string (for space only separators),
            # for example:
            #   --- ""
            if tk.len == 2:
                tk[1].expectKind nnkStrLit
                var sepLit = newLit("")
                if tk[1].strVal.len != 0: # add a label to current spearator
                    sepLit.strVal = tk[1].strVal
                result.add quote do:
                    cli.add(`sepLit`, `tKey`)
                continue
        # command identifier
        tk[1][0].expectKind nnkStrLit
        var
            newCommandId = tk[1][0]
            newCommandDesc = newNimNode(nnkStrLit)
            newCommandParams: seq[ParamTuple]
            isSubCommand: bool
            subCommandId: string
            parentCommands: seq[string]

        if newCommandId.strVal.contains("."):
            # Determine if this will be a command or a subcommand
            # by checking for dot annotations in `newCommandId` name
            # The maximum depth of a subcommand is by 3 levels.
            if count(newCommandId.strVal, '.') > 3:
                raise newException(KlymeneDefect, $MaximumDepthSubCommand % [newCommandId.strVal])
            elif newCommandId.strVal in registeredCommands:
                raise newException(KlymeneDefect, $ConflictCommandName % [newCommandId.strVal])
            parentCommands = split(newCommandId.strVal, '.')
            subCommandId = parentCommands[^1]
            parentCommands = parentCommands[0 .. ^2]
            for parentCommand in parentCommands:
                if parentCommand notin registeredCommands:
                    raise newException(KlymeneDefect, $ParentCommandNotFound % [parentCommand])
            isSubCommand = true

        # Store callback of current command in callbacks table
        let callbackFunction = newStmtList()
        let callbackIdent = getCallbackIdent()
        callbackFunction.add newDotExpr(newIdentNode(callbackIdent), newIdentNode("runCommand"))
        commandsConditional.add(
            nnkElifBranch.newTree(
                nnkInfix.newTree(
                    ident("=="),
                    ident("commandName"),
                    newLit(callbackIdent)
                ),
                newStmtList(newCall(callbackFunction))
            )
        )

        if tk[1][1].kind == nnkStrLit:    # Parse command description
            newCommandDesc = tk[1][1]
        elif tk[1][1].kind == nnkCommand:
            # Handle commands with static parameters
            for args in tk[1][1]:
                if args.kind == nnkIdent: #
                    newCommandParams.add (ptype: Key, pid: args.strVal)
                elif args.kind == nnkStrLit:
                    newCommandDesc = args
                elif args.kind == nnkTupleConstr:
                    for a in args:
                        if a.kind == nnkStrLit:
                            if a.strVal.startsWith("--"): # Variant-type params cannot contain flags
                                raise newException(SyntaxError, InvalidVariantWithFlags)
                            newCommandParams.add (ptype: Variant, pid: a.strVal)
                        else: raise newException(SyntaxError, InvalidVariantWithFlags)
                elif args.kind == nnkBracket:
                    for a in args:
                        if a.kind == nnkCharLit:    # handle short flags based on chars
                            newCommandParams.add (ptype: ShortFlag, pid: $(char(a.intVal)))
                        elif a.kind == nnkStrLit:  # handle long flags and parameters
                            var param = a.strVal
                            var paramType = Key
                            if a.strVal.startsWith("--"):
                                param = param[2..^1]
                                paramType = LongFlag
                            newCommandParams.add (ptype: paramType, pid: param)
        
        # store command id in registeredCommands
        registeredCommands.add(newCommandId.strVal)
        # Register the new command
        result.add quote do:
            var cmdId = `newCommandId`
            var isSubCommand: bool
            if `isSubCommand` != 0:
                cmdId = `subCommandId`
                isSubCommand = true
            cli.add(`newCommandId`, cmdId, `newCommandDesc`, `newCommandParams`, `callbackIdent`, isSubCommand = isSubCommand)

        # var levels = 2
        # while levels < tk.len:CommandParams`, true)
        #                 elif subcmd[1][1].kind == nnkInfix:
        #                     for a in subcmd[1][1]:
        #                         echo a.kind
        #             elif subcmd[1].kind == nnkStrLit:
        #                 echo subcmd[1].strVal
        #                 discard

        #             if subcmd.len > 2:
        #                 subcmd[2].expectKind(nnkStmtList)
        #                 subcmd[2][0].expectKind(nnkCommand)
        #                 let subCmdStmt = subcmd[2][0]
        #                 for subCmd in subCmdStmt:
        #                     var subCommandComment = newLit("")
        #                     if subCmd.kind == nnkPar:       # Handle subcommand Variant params
        #                         echo subCmd[0].strVal
        #                     elif subCmd.kind == nnkStrLit:  # Handle subcommand comment
        #                         subCommandComment.strVal = subCmd.strVal
        #     inc levels

    # TODO map command values
    result.add(
        nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                newCall(ident "declared", ident "aboutDescription"),
                newStmtList(
                    newAssignment(
                        newDotExpr(ident "cli", ident "canPrintExtras"),
                        ident("true")
                    )
                )
            )
        ),
        nnkWhenStmt.newTree(
            nnkElifBranch.newTree(
                newCall(ident "declared", ident "appVersion"),
                newStmtList(
                    newAssignment(
                        newDotExpr(ident "cli", ident "showAppVersion"),
                        ident "appVersion"
                    )
                )
            )
        ),
        newLetStmt(ident "commandName",
            newCall(newDotExpr(ident("cli"), ident("printUsage")))
        ),
        commandsConditional
    )
