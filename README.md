<p align="center">
  Kapsis CLI framework – Your type of CLI ;)
</p>

<p align="center">
  <code>nimble install nimbase</code>
</p>

<p align="center">
  <a href="https://github.com/">API reference</a>
</p>

## Key features
- [x] Macro-based CLI definition
- [x] Data validation and type checking
- [x] Beautified and indented Usage
- [x] Shows Extras, version and license in the help message
- [x] Supports subcommands and nested subcommands
- [x] Supports flags and options with or without values
- [x] Detailed error messages for invalid input
- [x] Pluggable Commands via Shared libraries
- [ ] Translatable Commands

## About
Kapsis is a framework for building extensible and user-friendly command line interfaces. It provides a validation system for user input, alignment and formatting for the **Usage** screen, and a fancy API for defining commands and their data. 

### Quick Example
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

### Metadata
Kapsis can collect metadata from the provided statements, but if not provided it will try to extract it from the `.nimble` file, so you can choose to provide it in either place. The metadata includes:
- `name`: The name of the application, used in the help message and as the default command.
- `version`: The version of the application, shown in the help message.
- `description`: A short description of the application, shown in the help message.
- `license`: The license of the application, shown in the help message.

### Pluggable Commands
Kapsis apps can discover and run subcommands contributed by plugins at runtime. A plugin is a shared library built with `--app:lib` that imports a Kapsis-specific CLI DSL (`kapsis/pluginapi`) and exports a JSON command manifest. Enable plugin support in your app with a `plugins do:` block:

```nim
initKapsis do:
  plugins do:
    # directory (relative to the app executable) where plugins are distributed
    dir: "plugins"
  commands do:
    # ... built-in commands, as usual
```

The Kapsis host scans two locations for plugins:

- **Global**: `~/.kapsis/apps/<app>/plugins`
- **Local**: the directory given to `plugins do: dir:` (resolved against the app executable's parent directory), when provided

Each enabled command is merged into the app's routing and appears in the Usage/`--help` screen, so users run it just like a built-in subcommand, e.g. `myapp greet Alice`.

#### Authoring a plugin
Plugins are written against `kapsis/pluginapi` (import `pkg/pluginkit` + `pkg/kapsis/pluginapi`) and built with `--app:lib`. They reuse the same Kapsis Values/argument DSL:

```nim
import pkg/kapsis/pluginapi

commands do:
  greet name.string, ?string(greeting):
    ## Greet someone
    echo "hello ", v.get("name").getStr

  colors:
    blue bool(enable):
      echo "blue = ", v.get("enable").getBool
```

The plugin framework emits the runtime manifest and command entrypoints automatically; the host loads the library, reads the manifest, and invokes the matching runner with the raw CLI arguments as JSON.

### Create a Kapsis plugin
Author a plugin as a pluginkit shared library (usually in its own package with a `kapsis_plugin.nimble`), wrapping the `commands do:` DSL in pluginkit's `plugin` macro:

```nim
import pkg/pluginkit
import pkg/kapsis/pluginapi

plugin myplugin, {
  name: "MyPlugin",
  author: "Your Name",
  description: "Contributes some subcommands",
  license: "MIT",
  version: "1.0.0"
}:
  commands do:
    greet name.string, ?string(greeting):
      ## Greet someone
      echo "hello ", v.get("name").getStr
```

Build it with the library backend:

```bash
nimble c --app:lib src/myplugin   # produces libmyplugin.dylib / .so / .dll
```

To load it, drop the built library into your app's plugin directory and enable plugins on the host:

```nim
initKapsis do:
  plugins do:
    # relative to the app executable; also pick "~/.kapsis/apps/myapp/plugins"
    dir: "plugins"
  commands do:
    # built-in commands as usual
```

Running the app now exposes the plugin's commands, e.g. `myapp greet Alice`, and they're listed on the Usage/`--help` screen alongside any built-in commands.

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/kapsis/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/kapsis/fork)

### 🎩 License
MIT license | [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
