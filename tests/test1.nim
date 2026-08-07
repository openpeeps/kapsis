# Kapsis test suite.
#
# Run with `nimble test` from the repository root.

import unittest

import pkg/kapsis/runtime
import pkg/kapsis/pluginapi

suite "values":
  test "string argument":
    var args = @[PluginArg(
      name: "name",
      datatype: ktString,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"name":"Alice"}""", args)
    let v: Values = addr table
    check v.get("name").getStr == "Alice"
    check v.has("name")

  test "optional string argument is absent when not provided":
    var args = @[PluginArg(
      name: "name",
      datatype: ktString,
      kind: cmdArgument,
      optional: false),
    PluginArg(
      name: "greeting",
      datatype: ktString,
      kind: cmdArgument,
      optional: true)]
    var table = jsonArgsToValues("""{"name":"Alice"}""", args)
    let v: Values = addr table
    check v.get("name").getStr == "Alice"
    check not v.has("greeting")

  test "bool flag":
    var args = @[PluginArg(
      name: "enable",
      datatype: ktBool,
      kind: cmdArgument,
      optional: false)]
    var enableTable = jsonArgsToValues("""{"enable":"true"}""", args)
    check (addr enableTable).get("enable").getBool == true

  test "getters are generated for each value type":
    var args = @[PluginArg(
      name: "count",
      datatype: ktInt,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"count":"42"}""", args)
    check (addr table).get("count").getInt == 42

suite "types":
  test "type names round-trip through CmdArgValueType":
    check ($ktString) == "string"
    check ($ktBool) == "bool"
    check ($ktInt) == "int"
    check toValueType("string") == ktString
    check toValueType("bool") == ktBool
    check toValueType("int") == ktInt