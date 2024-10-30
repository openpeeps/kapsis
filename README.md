<p align="center">
  <img src="https://raw.githubusercontent.com/openpeeps/kapsis/main/.github/logo.png" width="225px" alt="kapsis framework"><br>
  Kapsis &mdash; Build delightful & intuitive command line interfaces with Nim language 👑
</p>

<p align="center">
  <code>nimble install kapsis</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/kapsis/">API reference</a><br><br>
  <img src="https://github.com/openpeeps/kapsis/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeeps/kapsis/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- Typed arguments and validation (`path`, `string`, `int`, `bool`, `float`, `seconds` and more)
- Prompters `input`, `dropdown`, `secret`, `checkbox`, `radio`
- Commands and Sub commands
- Label separators
- Index Auto alignment
- Doc comments

### Example

```nim
  import commands/cli

  commands:
    -- "Source-to-Source"
    src string(-s), path(`timl`), bool(--pretty):
      ## Transpile `timl` code to a specific target source
    
    ast path(`timl`), filename(`output`):
      ## Generate binary AST from a `timl` file
```

### Command handles
Kapsis autolinks CLI commands to their command handles. For example, a command called `src`
autolinks to a command handle `srcCommand`

```nim
import kapsis/[app, cli]

proc srcCommand*(v: Values) =
  displayInfo("Hello")

proc astCommand*(v: Values) =
  discard
```

`-h`, `--help`, `-v` and `--version` are reserved flags.

### Database
todo

### Plugins
todo let others add more commands to your kapsis app via shared libraries.

# TODO
- Fancy Gradientful preloaders
- Fullscreen Session & Keyboard Events
- Auto-generate Bash/Zsh completion scripts
- Pluggable Commands via Shared Libraries
- Built-in database using either `JSON` or `SQLite`

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/kapsis/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/kapsis/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)
- 🥰 [Donate to The Enthusiast via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
`MIT` license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; 2024 OpenPeeps & Contributors &mdash; All rights reserved.
