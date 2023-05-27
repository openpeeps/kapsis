import std/[unittest, strutils, os, osproc]

let binPath = getCurrentDir() / "src" / "yacli.out"

test "can run":
  check fileExists(binPath)
  let o = execCmdEx(binPath)
  check o.exitCode == 0

test "can run command":
  let o = execCmdEx(binPath & indent("new app", 1))
  check(o.output.strip() == "Running new command with app option")
  check o.exitCode == 0

test "can run hello command":
  let o = execCmdEx(binPath & indent("hello", 1))
  check(o.output.strip() == "Hello")
  check o.exitCode == 0

test "can run hello.world command":
  let o = execCmdEx(binPath & indent("hello.world", 1))
  check(o.output.strip() == "Hello World!")
  check o.exitCode == 0