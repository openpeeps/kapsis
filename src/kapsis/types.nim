# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import std/[times, json, uri, net, os, tables, strutils, terminal]

import pkg/voodoo/setget
import pkg/openparser/json

export expandGetters

type
  CmdArgValueType* = enum
    ## The actual value types that will be used at runtime
    ## for parsing command line arguments
    ktString = "string"
    ktBool = "bool"
    ktInt = "int"
    ktFloat = "float"
    ktFile = "file"
    ktPath = "path"
    ktFilename = "filename"
    ktFilepath = "filepath"
    ktDir = "dir"
    ktMilliseconds = "miliseconds"
    ktSeconds = "seconds"
    ktMinutes = "minutes"
    ktHours = "hours"
    ktDays = "days"
    ktMonths = "months"
    ktYears = "years"
    ktJson = "json"
    ktYaml = "yaml"
    ktUrl = "url"
    ktPort = "port"
    ktIdent = "ident"
    ktAny = "any"
    ktList = "list"

  KapsisPath* = object
    ## The KapsisPath object that will hold the parsed value of a
    ## file or directory argument
    file*: FileInfo
    path*: string

  Value* {.getters.} = object
    ## The Value object that will hold the parsed value of a command line argument
    ## at runtime
    case kt: CmdArgValueType
    of ktString:
      vStr: string
    of ktBool:
      vBool: bool
    of ktInt:
      vInt: int
    of ktFloat:
      vFloat: float
    of ktFile:
      vFile: KapsisPath
    of ktPath:
      vPath: KapsisPath
    of ktFilename:
      vFilename: string
    of ktFilepath:
      vFilepath: string
    of ktDir:
      vDir: KapsisPath
    of ktMilliseconds:
      vMilliseconds: Duration
    of ktSeconds:
      vSeconds: Duration
    of ktMinutes:
      vMinutes: Duration
    of ktHours:
      vHours: Duration
    of ktDays:
      vDays: Duration
    of ktMonths:
      vMonths: Duration
    of ktYears:
      vYears: Duration
    of ktJson:
      vJson: JsonNode
    of ktYaml:
      vYaml: string
    of ktUrl:
      vUrl: Uri
    of ktPort:
      vPort: Port
    of ktIdent:
      vIdent: string
    of ktAny:
      vAny: string
    of ktList:
      vItems: seq[string]
  
  ValuesTable* = OrderedTable[string, Value]
    ## The table that will hold the parsed values of the command line arguments
  Values* = ptr ValuesTable
    ## A pointer to a table that will hold the parsed values
    ## of the command line arguments

  NoValFlags* = object
    ## The boolean flags a CLI declares. `std/parseopt` only attaches a
    ## following token to a flag once it has been told which flags are
    ## valueless, so these have to be handed over explicitly; otherwise
    ## `--name value` yields an empty flag plus a stray positional and only
    ## the `--name:value` form works.
    shortFlags*: set[char]
      ## Single-character short flags, without the leading dash
    longFlags*: seq[string]
      ## Long flags, without the leading dashes

const
  NotAShortFlag* = '\0'
    ## Sentinel kept inside `NoValFlags.shortFlags`. `std/parseopt` gates
    ## `canTakeVal` on `card(shortNoVal) > 0`, so a CLI that declares no
    ## boolean short flag at all would find that `-f value` never picks up
    ## its value. A NUL character cannot collide with a real flag name, so
    ## it satisfies the check without changing any behaviour.

proc withShortFlagSentinel*(flags: NoValFlags): NoValFlags =
  ## Returns `flags` with `NotAShortFlag` added to its short-flag set
  result = flags
  result.shortFlags.incl NotAShortFlag

proc normalizeFlagCase*(args: seq[string]): seq[string] =
  ## Returns `args` with the *name* of every option token lowercased, which
  ## is what `std/parseopt` has to be fed for its case-sensitive
  ## `longNoVal`/`shortNoVal` lookups to agree with kapsis' case-insensitive
  ## flag matching.
  ##
  ## Only the name is touched: the `:`/`=` separator and everything after it,
  ## and every positional argument, are left exactly as the user typed them.
  ## The result still has to be quoted before being parsed as a command line,
  ## so values containing spaces survive.
  for arg in args:
    if arg.len < 2 or arg[0] != '-':
      result.add arg
      continue
    let isLong = arg.len > 2 and arg[1] == '-'
    var nameEnd = (if isLong: arg.len else: 2)
    for c in 2 ..< arg.len:
      if arg[c] in {':', '='}:
        nameEnd = c
        break
    result.add arg[0..<nameEnd].toLowerAscii & arg[nameEnd..^1]

type
  KapsisErrorMessage* = enum
    ## A list of possible error messages that can be thrown by Kapsis
    ## at runtime when parsing user's input or when executing commands
    ## 
    ## It can be used to create i18n error messages in different languages
    unknownOption = "Unknown option: $1",
    unknownCommand = "Unknown command: $1",
    unexpectedOption = "Unexpected option: $1",
    typeMismatch = "Type mismatch for `$1`. Expected $2"
    missingArgument = "Missing required argument: $1"
    invalidChoice = "Invalid choice for `$1`. Expected one of: $2"
    unsupportedInPlugin =
      "Repeatable `$1` arguments are not supported in plugins yet"

template printError*(msg: KapsisErrorMessage, arg: varargs[string]) =
  ## Print `msg` error with `args` and quit with `QuitFailure` exit code 
  setForegroundColor(fgRed)
  write(stdout, "Error:")
  resetAttributes()
  if arg.len == 0:
    write(stdout, " " & $(msg))
  else:
    write(stdout, " " & ($(msg) % arg))
  write(stdout, "\n")
  quit(QuitFailure)

template collectValues*(values: var ValuesTable,
    argName: string, val: sink string, arg) =
  ## This template is used to collect and parse the command line
  ## arguments passed by the user at runtime.
  block:
    var hasError: bool
    case arg.datatype
    of ktString:
      values[argName] =
        Value(kt: ktString, vStr: val)
    of ktBool:
      try:
        values[argName] =
          Value(kt: ktBool, vBool: parseBool(val))
      except ValueError: discard
    of ktInt:
      try:
        values[argName] =
          Value(kt: ktInt, vInt: parseInt(val))
      except ValueError: discard
    of ktFloat:
      try:
        values[argName] =
          Value(kt: ktFloat, vFloat: parseFloat(val))
      except ValueError: discard
    of ktFile:
      if fileExists(val):
        values[argName] = Value(kt: ktFile,
          vFile: KapsisPath(file: val.getFileInfo, path: val))
      else: discard
    of ktPath:
      values[argName] = Value(kt: ktPath,
        vPath: KapsisPath(file: val.getFileInfo, path: val))
    of ktFilename:
      if val.isValidFilename:
        values[argName] = Value(kt: ktFilename, vFilename: val)
      else: discard
    of ktFilepath:
        values[argName] = Value(kt: ktFilepath, vFilepath: val)
    of ktDir:
      if dirExists(val):
        values[argName] = Value(kt: ktDir,
          vDir: KapsisPath(file: val.getFileInfo, path: val))
      else: discard
    of ktMilliseconds:
      try:
        let v = parseInt(val)
        values[argName] = Value(kt: ktMilliseconds,
          vMilliseconds: initDuration(milliseconds = v))
      except ValueError: discard
    of ktSeconds:
      try:
        let v = parseInt(val)
        values[argName] = Value(kt: ktSeconds,
          vSeconds: initDuration(seconds = v))
      except ValueError: discard
    of ktHours:
      try:
        let v = parseInt(val)
        values[argName] = Value(kt: ktHours,
          vHours: initDuration(hours = v))
      except ValueError: discard
    of ktJson:
      try:
        let v: JsonNode = fromJson(val)
        values[argName] = Value(kt: ktJson, vJson: v)
      except OpenParserJsonError, ValueError: discard
    of ktUrl:
      try:
        let v = uri.parseUri(val)
        values[argName] = Value(kt: ktUrl, vUrl: v)
      except UriParseError: discard
    of ktPort:
      try:
        let v = Port(parseInt(val))
        values[argName] = Value(kt: ktPort, vPort: v)
      except ValueError: discard
    of ktIdent:
      if val.validIdentifier:
        values[argName] = Value(kt: ktIdent, vIdent: val)
    of ktAny:
      if val in arg.choices:
        values[argName] = Value(kt: ktAny, vAny: val)
      else:
        printError(invalidChoice, argName, arg.choices.join(", "))
    of ktList:
      # repeatable args accumulate one item per occurrence rather than
      # overwriting, so `-f a -f b` yields a two-item list
      if not values.hasKey(argName):
        values[argName] = Value(kt: ktList, vItems: @[val])
      else:
        values[argName].vItems.add val
    else: discard
    if not values.hasKey(argName):
      printError(typeMismatch, argName, $arg.datatype)

proc renameCallback(x: string): string {.compileTime.} =
  x.replace("getV", "get")

expandGetters(renameCallback)