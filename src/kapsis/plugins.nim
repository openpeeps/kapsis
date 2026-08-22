# Kapsis - Plugin system for CLI commands
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis
##
## This module implements the host side of the plugin system. When enabled, a CLI
## application built with Kapsis can discover subcommands contributed by shared
## libraries (plugins) that are created and managed with `pluginkit`. Plugins are
## looked up in a pre-defined global directory (`~/.kapsis/apps/<app>/plugins`) and,
## optionally, in a local directory chosen by the application's creator.

import std/[tables, os, strutils, json, parseopt, sequtils, options]

import pkg/pluginkit

import ./types
import ./interactive/prompts

export pluginkit

type
  PluginCmdArg* = object
    ## A command-line argument contributed by a plugin command.
    name*: string
    datatype*: CmdArgValueType
    kind*: CmdLineKind
    isOptional*: bool
    choices*: seq[string]

  PluginCommand* = object
    ## A subcommand contributed by a plugin shared library.
    name*, description*, symbol*: string
      ## The command name, its help description and the exported function symbol
      ## the host will invoke to run it.
    args*: seq[PluginCmdArg]
    plugin*: Plugin
      ## The plugin that owns this command (keeps the library loaded)

  PluginHost* = ref object
    ## Holds an active plugin manager and the commands discovered from plugins.
    manager*: PluginManager
    commands*: OrderedTable[string, PluginCommand]
      ## Maps a plugin command name to its definition

  PluginRunFn* = proc(jsonArgs: cstring): cstring {.cdecl.}

  PluginCommandLoadFn* = proc(): cstring {.cdecl.}

proc parseCmdKind(s: string): CmdLineKind =
  ## Maps a serialized argument `kind` back to a `CmdLineKind`.
  result = case s
    of "longOption": cmdLongOption
    of "shortOption": cmdShortOption
    else: cmdArgument

proc typeFromString(s: string): CmdArgValueType =
  parseEnum[CmdArgValueType](s)

proc globalPluginsDir(exePath: string): string =
  ## Returns the pre-defined global plugins directory: `~/.kapsis/apps/<app>/plugins`.
  ## The app name is derived from the executable's basename.
  getHomeDir() / ".kapsis" / "apps" / exePath.splitFile.name / "plugins"

proc pluginExtensions: seq[string] = @["dylib", "so", "dll"]

proc getCommands*(plugin: Plugin): Option[JsonNode] =
  ## Resolves the `plugin_event_load_commands` entrypoint exported by a plugin
  ## shared library and returns its CLI command manifest as a JSON array, or
  ## `none(JsonNode)` when the plugin does not contribute any commands.
  let fn = cast[PluginCommandLoadFn](
    plugin.getHandle().symAddr("plugin_event_load_commands"))
  if fn != nil:
    let raw = cstrToString(fn())
    if raw.len > 0:
      return some(parseJson(raw))
  none(JsonNode)

proc collectPluginCommands(host: PluginHost, dir: string) =
  ## Loads every plugin present in `dir` and registers the commands it contributes.
  if dir.len == 0 or not dirExists(dir):
    return
  for path in walkFiles(dir & "/*"):
    let ext = path.splitFile.ext
    if ext.len > 1 and (ext[1..^1].toLowerAscii notin pluginExtensions()):
      continue
    try:
      let pluginId = host.manager.load(path)
      activate(host.manager, pluginId)
      let plugin = host.manager.getPlugin(pluginId)
      let commands = plugin.getCommands()
      if commands.isSome:
        for c in commands.get:
          if not c.hasKey("name") or not c.hasKey("symbol"):
            continue
          var cmd = PluginCommand(
            name: c["name"].getStr,
            symbol: c["symbol"].getStr,
            description: (if c.hasKey("description"): c["description"].getStr else: ""),
            plugin: plugin
          )
          if c.hasKey("args"):
            for a in c["args"]:
              cmd.args.add PluginCmdArg(
                name: a["name"].getStr,
                datatype: typeFromString(a["type"].getStr),
                kind: parseCmdKind(a["kind"].getStr),
                isOptional: a["optional"].getBool,
                choices: (if a.hasKey("choices"):
                  a["choices"].getElems.mapIt(it.getStr) else: @[])
              )
          host.commands[cmd.name] = cmd
    except CatchableError:
      discard

proc initPluginHost*(exePath: string, localDir: string = ""): PluginHost =
  ## Initializes the plugin manager and scans both the global and (optionally) the
  ## local plugin directories, registering every contributed command on the host.
  result = PluginHost(manager: PluginManager())
  result.collectPluginCommands(globalPluginsDir(exePath))
  if localDir.len > 0:
    let dir =
      if isAbsolute(localDir): localDir
      else: exePath.parentDir / localDir
    result.collectPluginCommands(dir)

proc runPluginCommand*(host: PluginHost, name: string): JsonNode =
  ## Parses the command-line arguments for the plugin command `name` and invokes the
  ## exported entrypoint of the owning plugin. Returns the parsed JSON response.
  result = %*{"error": "Plugin command not found: " & name}
  if not host.commands.hasKey(name):
    return
  let cmd = host.commands[name]
  let fn = cast[PluginRunFn](cmd.plugin.getHandle().symAddr(cmd.symbol))
  if fn.isNil:
    result = %*{"error": "Plugin symbol not found: " & cmd.symbol}
    return

  # tokenize the user's input (skipping the command name itself)
  var p = quoteShellCommand(commandLineParams()).initOptParser
  var tokens = p.getopt.toSeq()

  var
    rawArgs = newJObject()
    values = ValuesTable()
    posIdx = 0

  var i = 1
  while i < tokens.len:
    case tokens[i].kind
    of cmdLongOption, cmdShortOption:
      let spell = (if tokens[i].kind == cmdLongOption: "--" else: "-") & tokens[i].key
      var arg: PluginCmdArg
      for x in cmd.args:
        if x.kind in {cmdLongOption, cmdShortOption} and x.name == spell:
          arg = x
          break
      if arg.name.len == 0:
        displayError("Unexpected option: " & spell)
      if tokens[i].val.len > 0:
        collectValues(values, spell, tokens[i].val, arg)
        rawArgs[spell] = %tokens[i].val
      else:
        collectValues(values, spell, "true", arg)
        rawArgs[spell] = %"true"
    of cmdArgument:
      while posIdx < cmd.args.len and cmd.args[posIdx].kind != cmdArgument:
        inc posIdx
      if posIdx < cmd.args.len:
        let arg = cmd.args[posIdx]
        collectValues(values, arg.name, tokens[i].key, arg)
        rawArgs[arg.name] = %tokens[i].key
        inc posIdx
    else: discard
    inc i

  # validate required arguments
  for arg in cmd.args:
    if arg.kind == cmdArgument and not arg.isOptional and not values.hasKey(arg.name):
      printError(missingArgument, arg.name)
    elif arg.kind in {cmdLongOption, cmdShortOption} and not arg.isOptional:
      if not values.hasKey(arg.name):
        printError(missingArgument, arg.name)

  let resp = $fn(cstring($rawArgs))
  try:
    result = parseJson(resp)
  except CatchableError:
    result = %*{"error": resp}