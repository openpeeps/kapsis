import std/tables
from ./commands import Values, Parameter, ParameterType
from std/strutils import parseInt

export Values

proc flag*(values: Values, argName: string): bool =
  let cmd = values[]
  if cmd.hasKey(argName):
    result = cmd[argName].vLong

proc has*(values: Values, argName: string): bool =
  ## Determine if there is a value available for specified argument
  let cmd = values[]
  if cmd.hasKey(argName):
    let arg = cmd[argName]
    if cmd[argName].ptype == Variant:
      result = arg.vTuple.len != 0
    else:
      result = arg.vStr.len != 0

proc get*(values: Values, argName: string): string =
  ## Retrieve a value from a dynamic argument
  if values.has(argName):
    let arg = values[][argName]
    if arg.ptype == Variant:
      result = arg.vTuple
    else:
      result = arg.vStr

proc toInt*(str: string): int =
  result = parseInt(str)