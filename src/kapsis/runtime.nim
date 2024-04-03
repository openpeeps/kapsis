import std/[tables, strutils]

from ./app import Values, Value, KapsisValueType, expandGetters

proc has*(values: Values, key: string): bool =
  ## Checks if `values` contains an arg by `key`
  let cmd = values[]
  result = cmd.hasKey(key)

proc get*(values: Values, key: string): Value =
  ## Retrieve a `Value` from `values` by `key`
  result = values[][key]