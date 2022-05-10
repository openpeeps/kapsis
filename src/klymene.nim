# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene
#       
#       https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

import klymene2/commands
export commands

when isMainModule:
    # Optionally, you can adjust Klymene settings
    # https://changaco.oy.lc/unicode-progress-bars/
    # https://mike42.me/blog/2018-06-make-better-cli-progress-bars-with-unicode-block-characters
    settings(
        generateBashScripts = true,
            # Generate Bash Autocomplete scripts
            # for all commands, arguments and flags
        useSmartHighlight = true,
            # Highlight possible commands matches on invalid inputs
    )

    ## Define your Commands
    about:
        "Klymene ✨ Build delightful Command Line Interfaces."
        "Made by Humans from OpenPeep"
        version "1.4.5"

    commands:
        --- "Generals"
        $ "new"                                 "Create a project or package":
            $ "project"                         "Create a new project at current location"
            $ "package": ("git|license|ola")    "Create a new package at current location"
        
        --- "Server"
        $ "build"                               "Generate Binary AST for all Enkava rules"
        $ "serve" ["config", 'a', "--all", "asa"]      "Enkava as a REST API Microservice"
        $ "save" ("data", "output")             "Save data to given path"
        
        --- "Database"
        $ "database"                            "Manage your database"
        $ "migration"                           "Run database migration"
        $ "backup"  ("all", "table", "only")    "Create a database backup, either full, or for a specific table"
        
        --- "Maintenance"
        $ "up"                                  "Brings the app back online"
        $ "down"                                "Put app in maintenance mode"
