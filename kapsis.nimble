# Package

version       = "0.1.1"
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
  exec "nim c --mm:arc --threads:on -o:./bin/kapsis src/kapsis.nim"

task plugin, "testing pluggable":
  exec "nim c --mm:orc --app:lib --noMain examples/testPlugin.nim" 

# task plugin2, "plugin 2":
#   exec "nim c --app:lib --noMain --gc:orc"