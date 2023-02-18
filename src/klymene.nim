# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
import klymene/commands
export commands

import klymene/db

when isMainModule:
  import ../examples/[newCommand, helloCommand, helloWorldCommand]

  App:
    about:
      # Optional. When not provided will use .nimble info
      "👋 Yay! My command line interface"

    commands:
      $ "new" ("app", "rest"):
        ?       "Create a new project"            # describe your command
        ? app   "Create a new WEB project"        # describe a specific argument
        ? rest  "Create a new REST API project"
      
      --- "Dev stuff"
      $ "hello":
        ? "A second command"
      
      $ "hello.world":
        ? "A sub command"