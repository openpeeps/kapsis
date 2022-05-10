# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
#       
#       https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

{.warning[Spacing]: off.}

import std/[tables, macros]

from std/sequtils import delete
from std/strutils import `%`, indent, spaces, join, startsWith
from std/os import commandLineParams, sleep

# dumpAstGen:
#     import klymene2/[newCommand, a, b, c, d]

type
    ParameterType* = enum
        Key, Variant, LongFlag, ShortFlag

    ParamTuple = tuple[ptype: ParameterType, pid: string]

    Parameter* = ref object
        case ptype: ParameterType
        of Key:
            key_id: string
        of Variant:
            keys_id: seq[string]
        of LongFlag:
            long_flag_id: string
        of ShortFlag:
            short_flag_id: string
    
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

proc token(tok: string): string {.inline.} =
    result = "\e[90m" & tok & "\e[0m"

template printIndex*[K: Klymene](cli: K, highlightKeys: seq[string], showExtras, showVersion, isSubCommand = false) =
    ## Print index with available commands, flags and parameters
    if showVersion: 
        echo cli.showAppVersion
        return
    var index: seq[string]
    var hasDelimiter: bool
    if cli.canPrintExtras and showExtras:
        when declared(aboutDescription):
            # if declared, adds a head comment above the commands containing
            # info about the author, a description and copyright notes
            index.add("\e[90m" & aboutDescription & "\e[0m")
    # var count: int  # counting commands
    for id, cmd in pairs(cli.commands):
        index.add("")
        if cmd.commandType == CommentLine:
            add index[^1], cmd.name & NewLine
            continue    # no need to parse command line separators
        var
            i = 0
            strCommand: string
            baseIndent = 2
            descIndentSize: int
            countDelimiters: int8
        let paramsLen = cmd.args.len
        add strCommand, indent(id, 2)
        for paramKey, parameter in pairs(cmd.args):
            case parameter.ptype:
            of Variant:     # ``Variant`` expose a group of params as a|b|c|d
                add strCommand,
                    if i == 0: indent(paramKey, 1) else: paramKey
                if (i + 1) != paramsLen: # add pipe separator for variant-based parameters
                    add strCommand, indent(token "|", 0)
                    hasDelimiter = true
                    inc countDelimiters
            of Key:         # ``Key`` params can handle dynamic strings
                add strCommand, indent("<" & "\e[0m" & paramKey & ">", 1)
            of ShortFlag:   # ``ShortFlag`` are optionals. Always prefixed with a single ``-``
                add strCommand, indent("-" & paramKey, 1)
            of LongFlag:    # ``LongFlag`` are optionals. Always prefixed with double ``--``
                add strCommand, indent("--" & paramKey, 1)
            inc i
        # inc count
        add index[^1], strCommand
        # TODO calculate the overall description indent size
        # needed based the longest command from current index
        descIndentSize = 45 - (strCommand.len) 
        
        if hasDelimiter:
            descIndentSize = (9 * countDelimiters) + descIndentSize
        # add command comment and align based on id and params len
        let descIndentSizeFinal = if isSubCommand: (baseIndent - 2 - descIndentSize) else: descIndentSize
        if id in highlightKeys:
            index[^1] = "\e[97;92m" & index[^1] & "\e[0m"
        add index[^1], indent("\e[90m" & cmd.description & "\e[0m", descIndentSize)
        add index[^1], NewLine
    echo index.join("")

template quitApp[K: Klymene](cli: K, shouldQuit: bool,
    showUsage = true, highlightKeys: seq[string] = @[], showExtras, showVersion = false) =
    # Template to quit app and print the current commands.
    if shouldQuit:
        if showUsage:
            cli.printIndex(highlightKeys, showExtras, showVersion)
        quit()

proc printUsage*[K: Klymene](cli: var K) =
    ## Parse and print usage basde on given command line parameters
    var inputArgs: seq[string] = commandLineParams()
    
    cli.quitApp(inputArgs.len == 0)           # quit & prompt usage when missing args
    let inputCmd = inputArgs[0]
    if cli.hasCommand(inputCmd) == false:
        if inputArgs[0] in ["-h", "--help"]:
            # Quit and prompt usage with ``showExtras``
            # for displaying extra comments and options
            cli.quitApp(true, showExtras = true)
        elif inputArgs[0] in ["-v", "--version"]:
            cli.quitApp(true, showVersion = declared(appVersion))

        let suggested = cli.cmdStartsWith(inputCmd)
        if suggested.status == true:          # quit and highlight possible matches
            cli.quitApp(true, highlightKeys = suggested.commands)
        else: cli.quitApp(true)               # quit and prompt index
    inputArgs.delete(0)                         # delete command name from current seq

    if cli.hasAnyParams(inputCmd):
        let command: Command = cli.commands[inputCmd]
        for inputArg in inputArgs:
            var p: string
            if inputArg.startsWith("--"):   p = inputArg[2..^1] # long flag
            elif inputArg[0] == '-':        p = inputArg[1..^1] # short flag
            else:                           p = inputArg
            # Quit, prompt usage and highlight
            # the command when provided arguments are not valid
            cli.quitApp(command.args.hasKey(p) == false, highlightKeys = @[inputCmd])

            let parameter = command.args[p]
            case parameter.ptype:
            of Key:
                echo parameter.key_id
            of Variant:
                echo parameter.keys_id
            of ShortFlag:
                echo "short flag"
            of LongFlag:
                echo "long flag"
    else:
        cli.quitApp(inputArgs.len != 0) # quit when a command does not support extra args
        let command: Command = cli.commands[inputCmd]
        echo "running command: " & inputCmd

proc add*[K: Klymene](cli: var K, id: string, key: int) =
    ## Add a new command separator, with or without a label
    let sepId = id & "__" & $key
    var label = if id.len != 0: "\e[1m" & id  & ":\e[0m" else: id
    cli.commands[sepId] = Command(commandType: CommentLine, name: label)

proc add*[K: Klymene](cli: var K, id, desc: string, args: seq[ParamTuple], isSubCommand = false, isSeparator = false) =
    ## Private procedure for adding a new command
    ## to current Klymene instance. Commands are
    ## automatically registered via ``commands`` macro.
    if cli.commands.hasKey(id):
        raise newException(KlymeneError, "Duplicate command name for \"$1\"" % [id])

    cli.commands[id] = Command(commandType: CommandLine, name: id, description: desc)
    var baseIndent = if isSubCommand: 4 else: 2
    var descIndentSize: int
    # cli.printable[id] = indent(id, baseIndent) # add command name
    # add cli.printable, indent(id, 2)
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
                cli.commands[id].args[param.pid].keys_id.add(param.pid)
            of Key:
                # ``Key`` params can handle dynamic strings
                cli.commands[id].args[param.pid].key_id = param.pid
            of ShortFlag:
                # ``ShortFlag`` are optionals. Always prefixed with a single ``-``
                cli.commands[id].args[param.pid].short_flag_id = param.pid
            of LongFlag:
                # ``LongFlag`` are optionals. Always prefixed with double ``--``
                cli.commands[id].args[param.pid].long_flag_id = param.pid
    # else:
        # descIndentSize = if isSubCommand: id.len + (baseIndent - 2) else: id.len
        # add cli.printable[id], indent("\e[90m" & desc & "\e[0m", 30 - descIndentSize)
    # add cli.printable[id], NewLine

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
            nnkIdentDefs.newTree(
                newIdentNode("aboutDescription"),
                newIdentNode("string"),
                newEmptyNode()
            )
        ),
        nnkVarSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("appVersion"),
                newIdentNode("string"),
                newEmptyNode()
            )
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
    # var cli = Klymene()
    # cli = genSym(nskVar, "cli")
    result = newNimNode nnkStmtList
    result.add(
        nnkVarSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode("cli"),
                newEmptyNode(),
                nnkCall.newTree(newIdentNode("Klymene"))
            )
        )
    )

    var showDefaultLabel: bool
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
        # Call `add` proc for registering the new command
        # cli.add(commandId, commandDdescription, commandArguments)
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

    # printing commands usage
    result.add quote do:
        when declared(aboutDescription):
            cli.canPrintExtras = true
        when declared(appVersion):
            cli.showAppVersion = appVersion
        cli.printUsage()
