# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import std/[times, json, uri, net, os, tables, strutils]

import pkg/voodoo/setget
import pkg/jsony

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
  
  ValuesTable* = OrderedTable[string, Value]
    ## The table that will hold the parsed values of the command line arguments
  Values* = ptr ValuesTable
    ## A pointer to a table that will hold the parsed values
    ## of the command line arguments

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

template printError*(msg: KapsisErrorMessage, arg: varargs[string]) =
  ## Print `msg` error with `args` and quit with `QuitFailure` exit code 
  if arg.len == 0:
    display("\e[31mError:\e[0m " & $(msg))
  else:
    display("\e[31mError:\e[0m " & $(msg) % arg)
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
      except jsony.JsonError, ValueError: discard
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
    else: discard
    if not values.hasKey(argName):
      printError(typeMismatch, argName, $arg.datatype)

proc renameCallback(x: string): string {.compileTime.} =
  x.replace("getV", "get")

expandGetters(renameCallback)