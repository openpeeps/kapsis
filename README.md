<p align="center">
  <img src="https://raw.githubusercontent.com/openpeeps/klymene/main/.github/klymene.png" width="225px" alt="Klymene CLI framework"><br>
  Klymene &mdash; Build delightful command line interfaces with Nim language 👑
</p>

<p align="center">
  <code>nimble install klymene</code>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/openpeeps/klymene/main/.github/klymene-example.png" width="526px" alt="Klymene CLI Example"><br>
</p>

<p align="center">
  <a href="https://openpeep.github.io/klymene/">API reference</a><br><br>
  <img src="https://github.com/openpeeps/klymene/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeeps/klymene/workflows/docs/badge.svg" alt="Github Actions">
</p>


## 😍 Key Features
- [x] Generates Commands & Subcommands based on Nim's Macros
- [ ] CLI flat file Database `JSON`, `BSON`, `LMDB` or `SQLite`
- [ ] Plugins. Extend your CLI functionality
- [ ] Self Updater
- [ ] Auto-Generates Bash/ZSH Completion scripts
- [x] `Variants` using `tuple` syntax `(git|svn)`
- [x] Short/Long Flags `-r`, `--run`
- [ ] Colors, many colors 🌈
- [ ] ASCII & Gradientful Preloaders ⏳
- [ ] Prompters as `Input`, `Dropdown`, `Secret`, `Checkbox`, `Radio` 
- [ ] Fullscreen Sessions 🌌
- [ ] Keyboard Events ⌥
- [ ] Tables and Alignments 🗂
- [ ] UX - Highlight command for invalid inputs 🧐
- [ ] UX - Extra comments per command using `-h`
- [x] Written in Nim language 👑
- [x] Open Source | `MIT` License


## Example
Compile with `-d:debugcli` to show generated commands at compile-time 

```nim
import ./commands/[newCommand, helloCommand, helloWorldCommand]

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
    $ "hello":
      ? "A second command"
    $ "hello.world":
      ? "A sub command"
```

Once compiled run `myapp -h` to print:

```
👋 Yay! My command line interface

  new app|rest          Create a new project

Dev stuff:
  hello                 A second command
  hello.world           A sub command
```

Append a command with `-h` to show all flags/arguments, including description, for example
```
myapp new -h
```

**Note**: `-h`/`--help` and `-v`/`--version` are built-in flags (version is extracted from `.nimble` file)


### Imports & Callbacks
Each registered command requires an import statement.

If you add a new command called `new`, first you will need to import your command,
which in this case should be named `newCommand.nim`.

This is your `newCommand.nim`
```nim
import klymene/runtime

proc runCommand*(v: Values) =
  # my stuff
```

# TODO
Do the do. Add more examples

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/klymene/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/klymene/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)
- 🥰 [Donate to The Enthusiast via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
Klymene | `MIT` license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; 2023 OpenPeeps & Contributors &mdash; All rights reserved.