## Key features
- [x] Macro-based CLI definition
- [x] Data validation and type checking
- [x] Beautified and indented Usage
- [x] Shows Extras, version and license in the help message
- [x] Supports subcommands and nested subcommands
- [x] Supports flags and options with or without values
- [x] Detailed error messages for invalid input
- [ ] Pluggable Commands via Shared libraries
- [ ] Translatable Commands


## About
Kapsis is a framework for building extensible and user-friendly command line interfaces. It provides a validation system for user input, alignment and formatting for the **Usage** screen, and a fancy API for defining commands and their data. 

### Metadata
Kapsis can collect metadata from the provided statements, but if not provided it will try to extract it from the `.nimble` file, so you can choose to provide it in either place. The metadata includes:
- `name`: The name of the application, used in the help message and as the default command.
- `version`: The version of the application, shown in the help message.
- `description`: A short description of the application, shown in the help message.
- `license`: The license of the application, shown in the help message.

<p align="center">
<img src="https://raw.githubusercontent.com/openpeeps/kapsis/main/.github/Screen Shot 2026-04-06 at 17.37.30.png" alt="Screenshot" width="75%">
</p>

### Extensible API
You can build modular CLIs with Kapsis via plugins, which are just dynamic libraries that can be loaded at runtime. This allows everyone to create and share their own plugins with commands that can be loaded into other Kapsis applications.

The plugin-based architecture is very flexible and allows for a wide range of use cases, from simple command extensions to complex integrations with other tools and services.

```nim
import pkg/kapsis

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
```


### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/kapsis/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/kapsis/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
