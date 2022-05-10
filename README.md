<p align="center">
    <img src="https://raw.githubusercontent.com/openpeep/klymene/main/.github/klymene.png" width="225px" alt="Klymene"><br>
    Klymene &mdash; Build delightful Command Line Interfaces.
</p>

<p align="center">
    Originally started as a fork of Docopt package, now fully rewritten based on Nim's powerful Macros system.
</p>

## 😍 Key Features
- [x] Generates Commands & Subcommands based on Nim's Macros
- [ ] Auto-Generates Bash Completion scripts
- [ ] Colors, many colors 🌈
- [ ] ASCII & Gradientful Preloaders ⏳
- [ ] Prompters as `Input`, `Dropdown`, `Secret`, `Checkbox`, `Radio` 
- [ ] Fullscreen Sessions 🌌
- [ ] Keyboard Events ⌥
- [ ] Tables and Alignments 🗂
- [ ] UX - Highlight command for invalid inputs 🧐
- [ ] UX - Extra comments per command using `-h`
- [ ] Open Source | `MIT` License

## Install
```bash
nimble install klymene
```

## 🎉 My Command Line Interface
All magics happens under `commands` macro! Each command must be prefixed with `$` symbol.

You may want to add separators between commands, which can be done using `---` token followed by a
string `""` that, if filled can become a label, otherwise a simple space separator.

```nim
import klymene

about:
    "Klymene ✨ Build delightful Command Line Interfaces."
    "Made by Humans from OpenPeep"

commands:
    --- "Generals"
    $ "new"                                 "Create a project or package":
        $ "project"                         "Create a new project at current location"
        $ "package": ("git|license|ola")    "Create a new package at current location"
    
    --- "Server"
    $ "build"                               "Generate Binary AST for all Enkava rules"
    $ "serve" ["config", 'a', "--all"]      "Enkava as a REST API Microservice"
    $ "save" ("data", "output")             "Save data to given path"
    
    --- "Database"
    $ "database"                            "Manage your database"
    $ "migration"                           "Run database migration"
    $ "backup"  ("all", "table", "only")    "Create a database backup, either full, or for a specific table"
    
    --- "Maintenance"
    $ "up"                                  "Brings the app back online"
    $ "down"                                "Put app in maintenance mode"
```

## Klymene 💜 Bash/ZSH Completion Scripts
Klymene is able to auto-generate completion scripts for all commands.

### ❤ Contributions
If you like this project you can contribute to Klymene project by opening new issues, fixing bugs, contribute with code, ideas and you can even [donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C) 🥰

### 👑 Discover Nim language
<strong>What's Nim?</strong> Nim is a statically typed compiled systems programming language. It combines successful concepts from mature languages like Python, Ada and Modula. [Find out more about Nim language](https://nim-lang.org/)

<strong>Why Nim?</strong> Performance, fast compilation and C-like freedom. We want to keep code clean, readable, concise, and close to our intention. Also a very good language to learn in 2022.

### 🎩 License
Klymene is an Open Source Software released under `MIT` license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2022 OpenPeep & Contributors &mdash; All rights reserved.
