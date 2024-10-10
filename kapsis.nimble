# Package

version       = "0.2.0"
author        = "George Lemon"
description   = "Build delightful command line interfaces in seconds"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"
requires "illwill"
requires "checksums"
requires "https://github.com/openpeeps/voodoo"
# requires "pixie" # todo to generate beautiful showcase screen of the app
requires "jsony"
requires "valido"
requires "nancy"
requires "termstyle"
requires "curly"

task dev, "dev mode":
  exec "nim c --mm:arc --threads:on -o:./bin/kapsis src/kapsis.nim"

task screen, "build a cli screen for test":
  exec "nim c src/kapsis/interactive/screen.nim"
