# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "Build delightful command line interfaces"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.0"
requires "illwill"
requires "pkginfo"
requires "msgpack4nim#head"

task dev, "for test purposes":
  exec "nim c -r src/klymene.nim"