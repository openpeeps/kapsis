# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "Build delightful command line interfaces in seconds"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.0"
requires "illwill"
requires "pkginfo"
requires "msgpack4nim#head"

task dev, "dev mode":
  exec "nim c -r src/kapsis.nim"