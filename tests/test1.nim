import std/[unittest, strutils, os, osproc]

let binPath = getCurrentDir() / "src" / "klymene.out"

test "can init":
  check fileExists(binPath)
  let index = execCmdEx(binPath).output.split("\n")
  check index.len == 6
  check index[0][2..22] == "new app\e[90m|\e[0mrest"

test "can run command":
  let output = execCmdEx(binPath & indent("new app", 1)).output.strip()
  check(output == "Running new command with app option")

test "can handle unknown args":
  let output = execCmdEx(binPath & indent("new xyz", 1)).output.split("\n")
  check output[0] == "Unknown argument \"xyz\""

test "can print separator label":
  let index = execCmdEx(binPath).output.split("\n")
  check index[2] == "\e[1mDev stuff:\e[0m"

test "can call hello command":
  let output = execCmdEx(binPath & indent("hello", 1)).output.strip()
  check(output == "Hello")

test "can call hello.world command":
  let output = execCmdEx(binPath & indent("hello.world", 1)).output.strip()
  check(output == "Hello World!")