# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import ./kapsis/[framework, runtime]
export framework, tables

when isMainModule:
  proc installCommand(v: Values) =
    echo v.get("pkgname").getStr

  proc developCommand(v: Values) =
    echo "Hello, World!"

  proc buildCommand(v: Values) =
    echo "Hello, World!"  

  when isMainModule:
    initKapsis do:
      commands:
        -- "Package Manager"
        install string(pkgname), string("-x"):
          ## Installs a list of packages
        develop string(pkgname), int(age), string("-x"):
          ## Clones a list of packages for development. Adds them to a develop file if specified or
        build bool(pkgname):
          ## Builds a list of packages for development. Adds them to a develop file if specified or
