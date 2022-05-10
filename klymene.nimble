# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["klymene2"]
binDir        = "bin"


# Dependencies

requires "nim >= 1.7.1"
requires "illwill"
# requires "suru"

# after build:
#     exec "clear"

task dev, "Compile for development":
    echo "\n✨ Compiling for dev" & "\n"
    exec "nimble build --gc:arc --threads:on"

task prod, "Compile for production":
    echo "\n✨ Compiling for prod" & "\n"
    exec "nimble build -d:release --gc:arc --threads:on --opt:size -d:danger"