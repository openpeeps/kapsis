<p align="center">
    <img src="https://raw.githubusercontent.com/openpeep/klymene/main/.github/klymene.png" width="225px" alt="Klymene"><br>
    Klymene &mdash; Build delightful command line interfaces with Nim language.
</p>

## 😍 Key Features
- [x] Generates Commands & Subcommands based on Nim's Macros
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
- [ ] Open Source | `MIT` License

## Install
```bash
nimble install klymene
```

```nim
import myapp/newCommand

App:
  about:
    "👋 Yay! My command line interface"
    version "0.1.0"

  commands:
    $ "new" ("app", "rest"):
      ?       "Create a new project" 
      ? app   "Create a new WEB project"
      ? rest  "Create a new REST API project"
```

# TODO
Do the do. Add more examples

### 🎩 License
Klymene is an Open Source Software released under `MIT` license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2022 OpenPeep & Contributors &mdash; All rights reserved.