import std/[tables, strutils]

from ./app import Values, Value, KapsisErrorMessage, KapsisValueType, KapsisPath,
  getStr, getBool, getFloat, getInt, getPath, getFile,
  getFilename, getDir, getMilliseconds, getSeconds,
  getMinutes, getHours, getDays, getMonths, getYears,
  getJson, getYaml, getUrl, printError

export Values, Value, KapsisValueType, KapsisPath,
  getStr, getBool, getFloat, getInt, getPath, getFile,
  getFilename, getDir, getMilliseconds, getSeconds,
  getMinutes, getHours, getDays, getMonths, getYears,
  getJson, getYaml, getUrl

proc has*(values: Values, key: string): bool =
  ## Checks if `values` contains an arg by `key`
  result = values[].hasKey(key)

proc get*(values: Values, key: string): Value =
  ## Retrieve a `Value` from `values` by `key`
  if likely(values.has(key)):
    return values[][key]
  printError(missingArg, key)

proc `$`*(x: KapsisPath): string =
  ## Get stringified path from `KapsisPath` object
  result = x.path
