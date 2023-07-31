# kepsis - Build delightful Command Line interfaces in seconds
# 
#   (c) 2023 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kepsis

import std/tables
from ./commands import Values, Parameter, ParameterType
from std/strutils import parseInt

export Values

proc flag*(values: Values, argName: string): bool =
  let cmd = values[]
  if cmd.hasKey(argName):
    case cmd[argName].ptype:
    of LongFlag:
      result = cmd[argName].vLong
    of ShortFlag:
      result = cmd[argName].vShort
    else: discard

proc has*(values: Values, argName: string): bool =
  ## Check for available value by given `argName`
  let cmd = values[]
  if cmd.hasKey(argName):
    let arg = cmd[argName]
    case cmd[argName].ptype
    of Variant:
      result = arg.vTuple.len != 0
    of Key:
      result = arg.vStr.len != 0
    else: raise newException(ValueError, "Flags can't hold values, yet")

proc get*(values: Values, argName: string): string =
  ## Retrieve available value by given `argName`
  if values.has(argName):
    let arg = values[][argName]
    case arg.ptype
    of Variant:
      result = arg.vTuple
    of Key:
      result = arg.vStr
    else: raise newException(ValueError, "Flags can't hold values, yet")

proc toInt*(str: string): int =
  result = parseInt(str)