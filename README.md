## Key features
- [x] Macro-based CLI definition
- [x] Data validation and type checking
- [x] Beautified and indented Usage
- [x] Shows Extras, version and license in the help message
- [x] Supports subcommands and nested subcommands
- [x] Supports flags and options with or without values
- [x] Detailed error messages for invalid input


## About
Kapsis is a framework for building extensible and user-friendly command line interfaces. It provides a validation system for user input, alignment and formatting for the **Usage** screen, and a fancy API for defining commands and their data. 

### Metadata
Kapsis can collect metadata from the provided statements, but if not provided it will try to extract it from the `.nimble` file, so you can choose to provide it in either place. The metadata includes:
- `name`: The name of the application, used in the help message and as the default command.
- `version`: The version of the application, shown in the help message.
- `description`: A short description of the application, shown in the help message.
- `license`: The license of the application, shown in the help message.


### Extensible API
You can build modular CLIs with Kapsis via plugins, which are just dynamic libraries that can be loaded at runtime. This allows everyone to create and share their own plugins with commands that can be loaded into other Kapsis applications.

The plugin-based architecture is very flexible and allows for a wide range of use cases, from simple command extensions to complex integrations with other tools and services.

```nim
import kapsis

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
      red:
        ## Red color command
      blue:
        ## Blue color command
```


### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/kapsis/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/kapsis/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
