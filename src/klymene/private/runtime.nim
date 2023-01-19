#
# Base API
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
    if cmd.commandType == CommentLine:
      index.add (cmd.name, "", 0, CommentLine)
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

    for i in 0 .. inputArgs.high:
      var p: string
      if inputArgs[i].startsWith("--"):   # get long flags
        p = inputArgs[i][2..^1]
      elif inputArgs[i][0] == '-':        # get short flags
        p = inputArgs[i][1..^1]
      else:                           # get variant or custom param
        p = inputArgs[i]
      # echo command.args

      if command.args.hasKey(p):
        case command.args[p].ptype:
        of Variant:
          if gotVariant:
            cli.error = "Choose one of the options"
            quitApp(cli, shouldQuit = true, showUsage = false, highlights = @[inputcmd])
          gotVariant = true
        of Key:
          echo command.args[p].key
        of ShortFlag:
          echo "short flag"
        of LongFlag:
          echo "long flag"
      elif command.index[0].ptype == Key:
        echo command.args[command.index[0].pid].key
      else:
        # Quit, prompt usage and highlight all possible
        # commands that match with given input (if any)
        if p in ["h", "help"] and command.args.hasKey(mainInputArg):
          cli.extras = command.args[mainInputArg].help
          quitApp(cli, shouldQuit = true, showUsage = false)
        else:
          cli.invalidArg = p
          quitApp(cli, true, highlights = @[inputCmd])
  else:
    quitApp(cli, inputArgs.len != 0) # quit when a command does not support extra args
    command = cli.commands[inputCmd]

  result = command.callbackName
