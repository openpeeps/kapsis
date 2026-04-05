# Kapsis - Your type of CLI framework
#
#   (c) 2026 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import ./kapsis/[framework, runtime]
export framework, tables

when isMainModule:
  #
  # Define your command handlers here
  #
  proc helloCommand(v: Values) =
    echo v.get("pkgname").getStr

  proc greetCommand(v: Values) =
    if v.has("greeting"):
      echo v.get("greeting").getStr
    echo v.get("name").getStr

  proc colorsOrangeCommand(v: Values) =
    echo "The one that is orangely out of its head"
  
  proc colorsBlueCommand(v: Values) =
    echo "Now everyone loves the new blue / Cause it’s the truest"

  proc colorsWhateverColorCommand(v: Values) =
    echo "Whatever color command"

  #
  # Init Kapsis with the defined commands
  #
  initKapsis do:
    commands do:
      -- "Crazy stuff"
      hello name.string, int(age), ?bool(verbose):
        ## Describe your command here
      
      -- "Another command"
      greet name.string, ?string(greeting):
        ## Greeting someone with an optional greeting message

      -- "Colors by Ken Nordine"
      colors:
        ## Colors are cool, let's have some fun with them
        blue bool(enable):
          ## Blue was the bluest blue can be blue
        orange bool(enable):
          ## The silly old color who lives next to red