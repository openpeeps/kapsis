version = "0.1.0"
author = "George Lemon"
description = "Create beautiful command line interfaces in Nim. Based on docopt."
license = "MIT"
srcDir = "src"

requires "nim >= 0.15.0"
requires "regex >= 0.11.1"
requires "unicodedb"
requires "illwill"

task test, "Test":
    exec "nimble c --verbosity:0 -r -y test/test"
    for f in listFiles("examples"):
        if f[^4..^1] == ".nim": exec "nim compile --verbosity:0 --hints:off " & f
