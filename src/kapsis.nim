# Kapsis - Build delightful command line
# interfaces in seconds
# 
#   (c) 2024 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/kapsis

import kapsis/app
export app

when isMainModule:
  import kapsis/runtime

  # callbacks
  proc putCommand(v: Values) =
    echo v.get("t").getInt
    echo "put command"

  proc getCommand(v: Values) =
    echo "get command"

  proc oneCommand(v: Values) =
    echo "one command"

  proc getSomeVersion: string =
    result = """
  Nim Compiler Version 2.0.0 [Linux: amd64]
  Compiled at 2023-08-01
  Copyright (c) 2006-2023 by Andreas Rumpf

  git hash: a488067a4130f029000be4550a0fb1b39e0e9e7c
  active boot switches: -d:release
    """

  # App:
  #   about:
  #     # Optional. When not provided will use .nimble info
  #     "👋 Yay! My command line interface"
  commands:
    # nnkAccQuoted
    #   are used to capture data from stdin,
    #   by default, all placeholder arguments
    #
    # nnkTupleConstr
    #   is used to create choices where user
    #   can choose one of the available options.
    #
    #   identifiers prefixed with `-` or `--`
    #   are parsed as flags. note that flags
    #   don't have a fixed position
    -- "Some headline"
    put string(`key`), (-t:int,--test:int):
    # put string `key`, int `age`, [salt, pepper, curry]:
        ## A short command description
        # Describing your parameters and flags is a common practice.
        # Use `?` prefix followed by the identifier (parameter/flag name)
        # in order to add additional descriptions
        ? salt  "Describe a parameter"
        ? pepper "Describe another parameter"
        ? curry "Describe curry parameter"

    get seconds(`key`), int(-t):
      ## Retrieve an entry from database

    # delete string(`key`), bool(`refresh`):
    #   ## Delete a key

    # hello string `name`, bool `enable`

    -- "Development"
    more:
      ## A list of sub commands
      one string(`hello`), int(-d):
        ## Something about this subcommand
  do:
    # Add extra information or overwrite
    # default data for the following flags
    # -h, --help, -v, --version 
    -v|--version = getSomeVersion()