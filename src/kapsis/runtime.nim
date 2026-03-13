import std/[tables, strutils, json]
import ./interactive/prompts

import ./types
export types

proc has*(values: Values, key: string): bool =
  ## Checks if `values` contains an arg by `key`
  result = values[].hasKey(key)

proc get*(values: Values, key: string): Value =
  ## Retrieve a `Value` from `values` by `key`
  if likely(values.has(key)):
    return values[][key]
  printError(missingArgument, key)

proc `$`*(x: KapsisPath): string =
  ## Get stringified path from `KapsisPath` object
  result = x.path
