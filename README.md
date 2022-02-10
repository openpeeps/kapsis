<p align="center">
    <img src="https://raw.githubusercontent.com/openpeep/klymene/main/.github/klymene.png" width="225px" alt="Klymene - CLI Toolkit written in Nim language"><br><strong>🌊 Klymene is a fancy CLI toolkit written in Nim. Originally, based on <a href="https://github.com/docopt/docopt.nim">docopt library</a>, Klymene provides additional features, tweaks and tricks for creating powerful command line interfaces (Work in progress)</strong>
</p>

# Features

- [ ] Interactive Preloaders
- [ ] Tables and Alignments
- [x] Confirmation Prompt
- [x] Regular Prompt
- [x] Dropdown Prompt
- [x] Secret Prompt
- [x] Execute Shell Commands

The following Usage example is taken from [Psypac, a Fast Package Manager for PHP development and production environments](https://github.com/psypac/psypac)

```bash
🌀 Psy Package Manager (0.1.0) for PHP development & production environments.
👉 For updates, check https://github.com/psypac/psy

Usage:
   init [--skip|--git]            Initialize a new project
   make <p> <t> [--skip|--git]    Start new project from a template

   search <pkg>                   Search for a package (local/remote)
   clone <pkg>... [--add]         Clone one or more packages from source
   add <pkg>...   [--remote]      Add one or more dependencies to your project
   remove <pkg>...                Remove one or more dependencies from your project
   delete <pkg>   [--all]         Delete a specific package from disk

   run doc [md|json|html]         Generate a beautiful API Documentation website of your project
   run inspector                  Check config and find what requirements, alerts or failures may occur
   run <script>                   Execute PHP callbacks or any command-line executables

   serve <port> <file>            Invoke the built-in PHP server for fast development, testing or demos
   stop <pid>                     Stop a PHP server running on given PORT

   set env (dev|prod)             Convert PHP class map rules to PSR-4/PSR-0 or opposite
   set api <token>                Set your API Channel for GitHub, GitLab or BitBucket

   get env                        Get environment of the current project (dev or prod)
   get stats                      Get usage, projects and other geek stats

   flush (zips|pkgs|temps)        Permanently delete files by category

Options:
     --add                        Clone a package and add to current project
     --all                        Select all versions of a package for remove and delete command
     --remote                     Add a package from remote to current project by invoking clone command
     --skip                       Skip interactive mode
  -h --help                       Show this screen.
  -v --version                    Show version.
```
_todo_

## Installation

## Contributions


### Inspiration and Improvements

Inspirational libraries
- https://github.com/charmbracelet/bubbletea
- https://github.com/charmbracelet/bubbles
- https://github.com/charmbracelet/harmonica


## License
