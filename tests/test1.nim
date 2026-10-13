# Kapsis test suite.
#
# Run with `nimble test` from the repository root.

import unittest

import pkg/kapsis/runtime
import pkg/kapsis/framework
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

  test "any argument accepts an allowed choice":
    var args = @[PluginArg(
      name: "flavor",
      datatype: ktAny,
      kind: cmdArgument,
      optional: false,
      choices: @["vanilla", "chocolate", "strawberry"])]
    var table = jsonArgsToValues("""{"flavor":"chocolate"}""", args)
    check (addr table).get("flavor").getAny == "chocolate"

  test "any argument is absent when not provided":
    var args = @[PluginArg(
      name: "flavor",
      datatype: ktAny,
      kind: cmdArgument,
      optional: true,
      choices: @["vanilla", "chocolate"])]
    var table = jsonArgsToValues("""{}""", args)
    check not (addr table).has("flavor")

  test "int argument parses from a string":
    var args = @[PluginArg(
      name: "count",
      datatype: ktInt,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"count":"42"}""", args)
    check (addr table).get("count").getInt == 42

  test "float argument parses from a string":
    var args = @[PluginArg(
      name: "ratio",
      datatype: ktFloat,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"ratio":"3.14"}""", args)
    check (addr table).get("ratio").getFloat == 3.14

  test "bool argument parses from a string":
    var args = @[PluginArg(
      name: "on",
      datatype: ktBool,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"on":"false"}""", args)
    check (addr table).get("on").getBool == false

  test "ident argument parses valid identifiers":
    var args = @[PluginArg(
      name: "id",
      datatype: ktIdent,
      kind: cmdArgument,
      optional: false)]
    var table = jsonArgsToValues("""{"id":"myIdent"}""", args)
    check (addr table).get("id").getIdent == "myIdent"

suite "types":
  test "type names round-trip through CmdArgValueType":
    check ($ktString) == "string"
    check ($ktBool) == "bool"
    check ($ktInt) == "int"
    check toValueType("string") == ktString
    check toValueType("bool") == ktBool
    check toValueType("int") == ktInt

  test "any type name round-trips":
    check ($ktAny) == "any"
    check toValueType("any") == ktAny

  test "list type name round-trips":
    check ($ktList) == "list"
    check toValueType("list") == ktList

suite "repeatable args":
  let fileArg = CmdArg(
    name: "--file",
    dataType: ktList,
    kind: cmdLongOption,
    isOptional: true)

  test "the first occurrence creates the list":
    var table: ValuesTable
    collectValues(table, "--file", "a", fileArg)
    check (addr table).get("--file").getItems == @["a"]

  test "later occurrences append instead of overwriting":
    var table: ValuesTable
    for item in ["a", "b", "c"]:
      collectValues(table, "--file", item, fileArg)
    check (addr table).get("--file").getItems == @["a", "b", "c"]

  test "each repeatable flag keeps its own list":
    var table: ValuesTable
    collectValues(table, "--file", "a", fileArg)
    collectValues(table, "--dir", "x", CmdArg(
      name: "--dir", dataType: ktList, kind: cmdLongOption, isOptional: true))
    collectValues(table, "--file", "b", fileArg)
    check (addr table).get("--file").getItems == @["a", "b"]
    check (addr table).get("--dir").getItems == @["x"]

  test "an absent repeatable flag has no entry":
    var table: ValuesTable
    check not (addr table).has("--file")

  test "values that look like other types are kept verbatim":
    var table: ValuesTable
    collectValues(table, "--file", "12", fileArg)
    collectValues(table, "--file", "true", fileArg)
    check (addr table).get("--file").getItems == @["12", "true"]