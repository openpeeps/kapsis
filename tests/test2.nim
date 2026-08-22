# Kapsis CLI integration tests.
#
# These compile a small fixture kapsis app once (at test compile time) and then
# run it as a subprocess with different arguments, asserting on the parsed
# command dispatch, help output, argument validation and error handling.

import std/[os, osproc, strutils, unittest]

const fixtureDir = currentSourcePath().parentDir() / "fixtures"
const cliSrc = fixtureDir / "cliapp.nim"
const kapsisSrc = currentSourcePath().parentDir() / ".." / "src"
const cliBin =
  when defined(windows):
    fixtureDir / "cliapp.bin.exe"
  else:
    fixtureDir / "cliapp.bin"

static:
  # Build the fixture app once so the tests can run it as a subprocess
  discard staticExec("nim c --hints:off --warnings:off --path:\"" &
    kapsisSrc & "\" -o:\"" & cliBin & "\" \"" & cliSrc & "\"")

proc stripAnsi(s: string): string =
  var i = 0
  while i < s.len:
    if s[i] == '\e' and i + 1 < s.len and s[i + 1] == '[':
      inc i, 2
      while i < s.len and s[i] notin {'m', 'K'}:
        inc i
      if i < s.len: inc i
    else:
      result.add(s[i])
      inc i

proc runCLI(args: string): string =
  let (output, _) = execCmdEx("\"" & cliBin & "\" " & args)
  stripAnsi(output)

suite "cli help":
  test "shows commands with types and any choices in -h":
    let res = runCLI("-h")
    check "hello <name:string>" in res
    check "pick <flavor:any[vanilla,chocolate,strawberry]>" in res
    check "--debug:bool" in res

  test "shows metadata declared in the initKapsis block":
    let res = runCLI("-h")
    check "Test CLI" in res
    check "(c) Test | MIT License" in res
    check "Build Version: 1.0.0" in res

  test "shows commands in basic mode":
    let res = runCLI("")
    check "hello <name>" in res
    check "pick <flavor>" in res

suite "cli dispatch":
  test "executes a command with a string argument":
    check runCLI("hello Alice").strip() == "hello:Alice"

  test "optional string argument is read when present":
    check runCLI("greet Bob").strip() == "greet:Bob"

  test "optional string argument is skipped when absent":
    check runCLI("greet").strip() == "greet:"

  test "executes a command with an int argument":
    check runCLI("serve 8080").strip() == "serve:8080"

  test "a bool flag is true when present":
    check runCLI("debug --debug").strip() == "debug:true"

  test "a bool flag is false when absent":
    check runCLI("debug").strip() == "debug:false"

  test "runs a subcommand":
    check runCLI("colors.blue true").strip() == "colors-blue:true"

  test "runs a nested subcommand":
    check runCLI("colors.all").strip() == "colors-all"

suite "cli any validation":
  test "accepts an allowed choice":
    check runCLI("pick chocolate").strip() == "pick:chocolate"

  test "rejects a choice that is not in the list":
    let res = runCLI("pick mint")
    check "Invalid choice for `flavor`" in res
    check "vanilla, chocolate, strawberry" in res

  test "missing required any argument reports the argument":
    let res = runCLI("pick")
    check "Missing required argument: flavor" in res

suite "cli errors":
  test "reports unknown commands":
    let res = runCLI("nope")
    check "Unknown command: nope" in res

  test "reports missing required arguments":
    let res = runCLI("serve")
    check "Missing required argument: port" in res

suite "cli case-insensitive flags":
  test "long flags resolve regardless of case":
    check runCLI("cased --SKIPFLAGS").strip() == "skip:true\ny:false"
    check runCLI("cased --skipflags").strip() == "skip:true\ny:false"

  test "short flags resolve regardless of case":
    check runCLI("cased -Y").strip() == "skip:false\ny:true"

  test "values are keyed by the declared flag name":
    # the handler reads the canonical `--skipFlags` name; if collected
    # values were keyed by the user's spelling, this would print false
    check runCLI("cased --SkipFlags --skipflags").strip() == "skip:true\ny:false"

  test "builtin help and version flags are case-insensitive":
    check "Test CLI" in runCLI("--HELP")
    check "1.0.0" in runCLI("-V")

suite "cli duplicate flag detection":
  test "flags differing only by case are rejected at compile time":
    let (outp, code) = execCmdEx("nim c --hints:off --warnings:off --path:\"" &
      kapsisSrc & "\" -o:\"" & (fixtureDir / "dupflag.bin") & "\" \"" &
      (fixtureDir / "dupflag.nim") & "\"")
    check code != 0
    check "Duplicate flag definition" in outp
