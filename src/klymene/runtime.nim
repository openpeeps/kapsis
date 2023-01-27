import std/tables
from ./commands import Values, Parameter

export Values

proc flag*(values: Values, argName: string): bool =
  let cmd = values[]
  if cmd.hasKey(argName):
    result = cmd[argName].vLong