import std/[unittest, strutils, os, osproc]

let binPath = getCurrentDir() / "src" / "klymene.out"

test "can init":
  check fileExists(binPath)
  let index = execCmdEx(binPath).output.split("\n")
  check index.len == 2
  check index[0][2..22] == "new app\e[90m|\e[0mrest"

test "can run command":
  let output = execCmdEx(binPath & indent("new app", 1)).output.strip()
  check(output == "Running new command with app option")

test "can handle unknown args":
  let output = execCmdEx(binPath & indent("new xyz", 1)).output.split("\n")
  check output[0] == "Unknown argument \"xyz\""