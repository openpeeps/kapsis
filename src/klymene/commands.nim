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
from std/strutils import `%`, indent, spaces, join, startsWith
from std/os import commandLineParams, sleep
from std/algorithm import sorted, SortOrder

type
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
        CommandLine, CommentLine

    Command* = object
        name: string
        case commandType: CommandType
        of CommandLine:
            description: string
            args: OrderedTable[string, Parameter]
        else: discard

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

    KlymeneError = object of CatchableError
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
    ## Determine if given ``Command`` has flags
    for k, p in pairs(cmd.args):
        if p.ptype in {ShortFlag, LongFlag}:
            return true

proc commandExists*[K: Klymene](cli: K, key: string): bool =
    result = cli.commands.hasKey(key)

template getValue*[V: Value](val: V): any =
    ## A callable template to retrieve values from a ``runCommand`` proc
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

proc printIndex*[K: Klymene](cli: K, highlightKeys: seq[string], showExtras, showVersion, isSubCommand = false) =
    ## Print index with available commands, flags and parameters
    if showVersion: 
        echo cli.showAppVersion
        return

    # A sequence holding the total length of commands (with args and separators)
    var commandsLen: seq[int]
    var index: seq[tuple[command, description: string, delimiters, commandLen: int]]
    # Parse registered commands and prepare for printing
    for id, cmd in pairs(cli.commands):
        # index.add("")
        if cmd.commandType == CommentLine:
            # add index[^1], cmd.name & NewLine
            continue    # no need to parse command line separators
        var
            i = 0
            strCommand: string
            baseIndent = 2
            countDelimiters: int
        let paramsLen = cmd.args.len
        add strCommand, id
        commandsLen.add(strCommand.len)
        for paramKey, parameter in pairs(cmd.args):
            case parameter.ptype:
            of Variant:     # ``Variant`` expose a group of params as a|b|c|d
                add strCommand,
                    if i == 0: indent(paramKey, 1) else: paramKey
                inc(commandsLen[^1], paramKey.len)
                if (i + 1) != paramsLen: # add pipe separator for variant-based parameters
                    add strCommand, indent(token "|", 0)
                    inc countDelimiters
            of Key:         # ``Key`` params can handle dynamic strings
                add strCommand, indent("<" & "\e[0m" & paramKey & ">", 1)
                inc(commandsLen[^1], paramKey.len + 3) # plus `<` and `>` and 1 space
            of ShortFlag:   # ``ShortFlag`` are optionals. Always prefixed with a single ``-``
                add strCommand, indent("-" & paramKey, 1)
                inc(commandsLen[^1], paramKey.len + 2) # plus `-` and 1 space
            of LongFlag:    # ``LongFlag`` are optionals. Always prefixed with double ``--``
                add strCommand, indent("--" & paramKey, 1)
                inc(commandsLen[^1], paramKey.len + 3) # plus `--` and 1 space
            inc i
        
        inc(commandsLen[^1], countDelimiters)
        index.add (strCommand, cmd.description, countDelimiters, commandsLen[^1])

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
        if i.command in highlightKeys:
            i.command = "\e[97;92m" & i.command & "\e[0m"
        let baseIndent = 10 + (baseCmdIndent - i.commandLen - i.delimiters)
        add usageOutput, indent(i.command, 0)
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
            # Quit and prompt usage with ``showExtras``
            # for displaying extra comments and options
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
    result = command.name & "Command"

proc add[K: Klymene](cli: var K, id: string, key: int) =
    ## Add a new command separator, with or without a label
    let sepId = id & "__" & $key
    var label = if id.len != 0: "\e[1m" & id  & ":\e[0m" else: id
    cli.commands[sepId] = Command(commandType: CommentLine, name: label)

proc add[K: Klymene](cli: var K, id, desc: string, args: seq[ParamTuple], isSubCommand = false, isSeparator = false) =
    ## Add a new command to current Klymene instance. Commands are registered
    ## automatically from ``commands`` macro.
    if cli.commands.hasKey(id):
        raise newException(KlymeneError, "Duplicate command name for \"$1\"" % [id])
    cli.commands[id] = Command(
        commandType: CommandLine,
        name: id,
        description: desc
    )

    if args.len != 0:
        var
            strCounter = 0      # holds params length
            strCommand: string
            hasDelimiter: bool
            countDelimiters: int8
        for k, param in pairs(args):
            if cli.commands[id].args.hasKey(param.pid):
                raise newException(KlymeneError, "Duplicate parameter name for \"$1\"" % [param.pid])
            cli.commands[id].args[param.pid] = Parameter(ptype: param.ptype)
            case param.ptype:
            of Variant:
                # ``Variant`` expose a group of params as a|b|c|d
                cli.commands[id].args[param.pid].variant.add(param.pid)
            of Key:
                # ``Key`` params can handle dynamic strings
                cli.commands[id].args[param.pid].key = param.pid
            of ShortFlag:
                # ``ShortFlag`` are optionals. Always prefixed with a single ``-``
                cli.commands[id].args[param.pid].sflag = param.pid
            of LongFlag:
                # ``LongFlag`` are optionals. Always prefixed with double ``--``
                cli.commands[id].args[param.pid].flag = param.pid

proc getCommands[K: Klymene](cli: var K): seq[string] {.inline.} =
    for cmdId in keys(cli.commands):
        if cmdId.startsWith("__"): continue
        result.add(cmdId)

macro about*(info: untyped) =
    ## Macro for adding info and other comments above usage commands.
    ## Informations provided via ``about`` macro will be shown only
    ## when user press ``app -h`` or ``app --help``
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

macro commands*(tks: untyped) =
    ## Macro for creating commands, subcommands
    tks.expectKind nnkStmtList
    
    # Init Klymene
    result = newStmtList(
        newVarStmt(ident "cli", newCall(ident("Klymene")))
    )

    var showDefaultLabel: bool
    var commandsConditional = newNimNode(nnkIfStmt)

    for tkey, tk in pairs(tks):
        tk[0].expectKind nnkIdent
        if tk[0].strVal != "$":
            if tk[0].strVal != TokenSeparator:
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
        var genCmdId = tk[1][0]
        var genCmdDesc = newNimNode(nnkStrLit)
        var genParams: seq[ParamTuple]

        # let test = toOrderedSet(["as", "asdasd"])
        # Store callback of current command in callbacks table
        let callbackFunction = newStmtList()
        let callbackIdent = genCmdId.strVal & "Command"
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
            genCmdDesc = tk[1][1]
        elif tk[1][1].kind == nnkCommand:
            # Handle commands with static parameters
            for args in tk[1][1]:
                if args.kind == nnkIdent: # 
                    genParams.add (ptype: Key, pid: args.strVal)
                elif args.kind == nnkStrLit:
                    genCmdDesc = args
                elif args.kind == nnkTupleConstr:
                    for a in args:
                        if a.kind == nnkStrLit:
                            if a.strVal.startsWith("--"): # Variant-type params cannot contain flags
                                raise newException(SyntaxError, InvalidVariantWithFlags)
                            genParams.add (ptype: Variant, pid: a.strVal)
                        else: raise newException(SyntaxError, InvalidVariantWithFlags)
                elif args.kind == nnkBracket:
                    for a in args:
                        if a.kind == nnkCharLit:    # handle short flags based on chars
                            genParams.add (ptype: ShortFlag, pid: $(char(a.intVal)))
                        elif a.kind == nnkStrLit:  # handle long flags and parameters
                            var param = a.strVal
                            var paramType = Key
                            if a.strVal.startsWith("--"):
                                param = param[2..^1]
                                paramType = LongFlag
                            genParams.add (ptype: paramType, pid: param)
        
        # Add the new command to cli
        result.add quote do:
            cli.add(`genCmdId`, `genCmdDesc`, `genParams`)

        var levels = 2
        while levels < tk.len:
            tk[levels].expectKind(nnkStmtList)
            for subcmd in tk[2]:
                if subcmd.kind == nnkPrefix:
                    if subcmd[0].eqIdent "$":
                        discard
                    elif subcmd[0].eqIdent "?":
                        echo "legend"
                    if subcmd[1].kind == nnkCommand:
                        subcmd[1][0].expectKind nnkStrLit
                        subcmd[1][1].expectKind nnkStrLit
                        var subCmdId = newLit(genCmdId.strVal & "." & subcmd[1][0].strVal)
                        let subCmdIdName = subcmd[1][1]
                        result.add quote do:
                            cli.add(`subCmdId`, `subCmdIdName`, `genParams`, true)
                    elif subcmd[1].kind == nnkStrLit:
                        echo subcmd[1].strVal
                        discard

                    if subcmd.len > 2:
                        subcmd[2].expectKind(nnkStmtList)
                        subcmd[2][0].expectKind(nnkCommand)
                        let subCmdStmt = subcmd[2][0]
                        for subCmd in subCmdStmt:
                            var subCommandComment = newLit("")
                            if subCmd.kind == nnkPar:       # Handle subcommand Variant params
                                echo subCmd[0].strVal
                            elif subCmd.kind == nnkStrLit:  # Handle subcommand comment
                                subCommandComment.strVal = subCmd.strVal
            inc levels

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
