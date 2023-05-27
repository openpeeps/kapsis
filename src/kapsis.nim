# kapsis - Build delightful Command Line interfaces in seconds
# 
#   (c) 2023 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import kapsis/commands
export commands

import kapsis/db

when isMainModule:
  import ../examples/[newCommand, helloCommand, helloWorldCommand]

  App:
    about:
      # Optional. When not provided will use .nimble info
      "👋 Yay! My command line interface"

    commands:
      --- "Main commands" # separator
      $ "new" ("app", "rest"):
        ?       "Create a new project"            # describe your command
        ? app   "Create a new WEB project"        # describe a specific argument
        ? rest  "Create a new REST API project"
      
      --- "Dev stuff" # separator with text
      $ "hello" `input` ["jazz"]:
        ? "A second command"
      $ "hello.world":
        ? "A sub command"