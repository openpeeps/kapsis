# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import ./kapsis/[framework, runtime]
export framework, tables

when isMainModule:
  proc helloCommand(v: Values) =
    echo v.get("pkgname").getStr

  proc greetCommand(v: Values) =
    if v.has("greeting"):
      echo v.get("greeting").getStr
    echo v.get("name").getStr

  proc colorsRedCommand(v: Values) =
    echo "Red color command, name: ", v.get("name").getStr
  
  proc colorsBlueCommand(v: Values) =
    echo "Blue color command, name: ", v.get("name").getStr

  when isMainModule:
    initKapsis do:
      commands do:
        -- "Crazy stuff"
        hello name.string, int(age), ?bool(verbose):
          ## This is a comment
        
        -- "Another command"
        greet name.string, ?string(greeting):
          ## Another comment

        -- "Subcommand example"
        colors:
          ## Colors command with subcommands
          red string(name):
            ## Red color command
          blue string(name):
            ## Blue color command