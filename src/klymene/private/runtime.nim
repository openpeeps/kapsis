#
# Base API
#

proc init[K: typedesc[Klymene]](cli: K): Klymene =
    ## Initialize an instance of Klymene
    result = cli()

method hasCommand(cli: Klymene, id: string): bool = 
    ## Determine if command exists by id
    result = cli.commands.hasKey(id)

method getCommand(cli: var Klymene, id: string): Command =
    ## Return a Command instance based on given `id`
    result = cli.commands[id]

method startsWith(cli: var Klymene, prefix: string): tuple[status: bool, commands: seq[string]] =
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

method expectParams(command: Command): bool =
    ## Determine if a command expect any parameters
    result = command.args.len != 0

# method getVariants(command: Command) =
#     var vars: seq[string]
#     for k, param in pairs(command.args):
#         if param.ptype == Variant:
#             vars = param.variant

# method hasFlags(command: Command): bool =
#     ## Determine if given `Command` has flags
#     for k, p in pairs(command.args):
#         if p.ptype in {ShortFlag, LongFlag}:
#             return true


#
# Print usage
#

proc style(str: string): string {.inline.} =
    result = "\e[90m" & str & "\e[0m"

method printAppIndex(cli: Klymene, highlights: seq[string],
                    showExtras, showVersion: bool) =
    ## Print index with available commands, flags and parameters
    if showVersion: 
        echo cli.appVersion
        return
    
    var commandsLen: seq[int]
    # a seq holding the total length of each command,
    # including arguments and separators. this is used
    # for usage alignment before printing.

    var index: seq[
        tuple[
            command, description: string,
            commandLen: int,
            commandType: CommandType
        ]
    ]

    # Parse registered commands and prepare for printing
    for id, cmd in pairs(cli.commands):
        if cmd.commandType == CommentLine:
            index.add (cmd.name, "", 0, CommentLine)
            continue
        
        var
            i = 0
            strCommand: string
            baseIndent = 2
        let paramsLen = cmd.args.len
        
        # write the stringified command line, starting
        add strCommand, cmd.commandName
        commandsLen.add strCommand.len
        for paramKey, parameter in pairs(cmd.args):
            # Parse command parameters in order to show in print usage
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

    # Get the highest length from commands
    # so we can setup the alignments
    let orderedCmds = sorted(commandsLen, system.cmp[int], order = SortOrder.Descending)
    let baseCmdIndent = orderedCmds[0]
    var usageOutput: string

    if cli.canPrintExtras and showExtras:
        # prepend extra information when pressing `-h` or `--help`
        when declared aboutDescription:
            # when available, shows app description containing
            # infos about the author, app and copyright notes.
            add usageOutput, "\e[90m" & aboutDescription & "\e[0m"
    if cli.error.len != 0:
        stdout.write(cli.error)
    elif cli.invalidArg.len != 0:
        stdout.write("Unknown argument \"$1\"\n\n" % [cli.invalidArg])

    for k, i in index.mpairs:
        if i.commandType == CommentLine:
            if k != 0:
                add usageOutput, NewLine
            add usageOutput, i.command
            add usageOutput, NewLine
            continue

        if i.command in highlights:
            i.command = "\e[97;92m" & i.command & "\e[0m"

        var baseIndent = 10 + (baseCmdIndent - i.commandLen)

        if i.commandType == SubCommandLine:
            # indent sub commands by 2 spaces
            baseIndent = baseIndent - 2
            add usageOutput, indent(i.command, 2)
        else:
            add usageOutput, i.command
        add usageOutput, indent("\e[90m" & i.description & "\e[0m", baseIndent)
        add usageOutput, NewLine
    stdout.write usageOutput


method quitApp(cli: Klymene, shouldQuit: bool, showUsage = true,
            highlights: seq[string] = @[], showExtras, showVersion = false) =
    ## Quits the current state and print the application index
    if shouldQuit:
        if showUsage:
            cli.printAppIndex(highlights, showExtras, showVersion)
        quit()

method printUsage*(cli: var Klymene): string =
    ## Parse and print usage based on given command line parameters
    var inputArgs: seq[string] = commandLineParams()
    quitApp(cli, inputArgs.len == 0)           # quit & prompt usage if missing args
    let inputCmd = inputArgs[0]

    if not cli.hasCommand inputCmd:
        if inputArgs[0] in ["-h", "--help"]:
            # Quit and prompt usage with `showExtras` for displaying extra comments and options
            quitApp(cli, true, showExtras = true)
        elif inputArgs[0] in ["-v", "--version"]:
            quitApp(cli, true, showVersion = declared(appVersion))

        let suggested = cli.startsWith inputCmd
        if suggested.status == true:            # quit and highlight possible matches
            quitApp(cli, true, highlights = suggested.commands)
        else: quitApp(cli, true)                # quit and prompt index
    inputArgs.delete(0)                         # delete command name from current seq

    var command: Command = cli.getCommand(inputCmd)
    if command.expectParams():
        var hasOneVariant: bool             # prevent multiple variants at once
        for inputArg in inputArgs:
            var p: string
            if inputArg.startsWith("--"):   # get long flags
                p = inputArg[2..^1]
            elif inputArg[0] == '-':        # get short flags
                p = inputArg[1..^1]
            else:                           # get variant or custom param
                p = inputArg

            let inputArgExists = command.args.hasKey(p)
            if not inputArgExists:
                # Quit, prompt usage and highlight all possible commands
                # that match with given input. if any
                cli.invalidArg = p
                quitApp(cli, true, highlights = @[inputCmd])

            let parameter = command.args[p]
            case parameter.ptype:
            of Variant:
                if hasOneVariant:
                    cli.error = "Only one variant at once"
                    quitApp(cli, true, highlights = @[inputcmd])
                hasOneVariant = true
            of Key:
                echo parameter.key
            of ShortFlag:
                echo "short flag"
            of LongFlag:
                echo "long flag"
    else:
        quitApp(cli, inputArgs.len != 0) # quit when a command does not support extra args
        command = cli.commands[inputCmd]
    result = command.callbackName
