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
- [x] `Variants` using `tuple` syntax `(git|svn)`
- [x] Short/Long Flags `-r`, `--run`
- [x] Handle `stdin` using `arrows` simply like `<path>`
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

Argument types
- Dynamic argument `<pkg>`
- One or more dynamic arguments `<pkg>...`
- Variants `("git"|"svn")`
- Short flags using char `'i'`
- Long flags using strings prefixed with `--`, `"--all"`

Built-in flags: `-h`, `--help`, `-v` and `--version`

## 🎉 My Command Line Interface
All magics happens under `commands` macro!

Create your commands one per line. Each command must be prefixed with `$` symbol.

### Basic Example
```nim
import klymene

commands:
    $ "install" <pkg>...           "Installs one or more packages."
```

### Full example
Use `about` macro to add extra information. This info is visible when user press `-h` or `--help`.

```nim
import klymene

about:
    "Klymene ✨ Build delightful Command Line Interfaces."
    "Made by Humans from OpenPeep"
    version "1.4.1"
# todo
```

## Klymene 💜 Bash/ZSH Completion Scripts
Klymene is able to auto-generate completion scripts for all commands.
TODO

### ❤ Contributions
If you like this project you can contribute to Klymene project by opening new issues, fixing bugs, contribute with code, ideas and you can even [donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C) 🥰

### 👑 Discover Nim language
<strong>What's Nim?</strong> Nim is a statically typed compiled systems programming language. It combines successful concepts from mature languages like Python, Ada and Modula. [Find out more about Nim language](https://nim-lang.org/)

<strong>Why Nim?</strong> Performance, fast compilation and C-like freedom. We want to keep code clean, readable, concise, and close to our intention. Also a very good language to learn in 2022.

### 🎩 License
Klymene is an Open Source Software released under `MIT` license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2022 OpenPeep & Contributors &mdash; All rights reserved.

<a href="https://hetzner.cloud/?ref=Hm0mYGM9NxZ4"><img src="https://openpeep.ro/banners/openpeep-footer.png" width="100%"></a>