<p align="center">
    <img src="https://raw.githubusercontent.com/openpeep/klymene/main/.github/klymene.png" width="225px" alt="Klymene"><br>
    <strong>Create beautiful command line interfaces in Nim. Based on docopt. (Work in progress)</strong>
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

## Examples
_todo_


### ❤ Contributions
If you like this project you can contribute to Klymene project by opening new issues, fixing bugs, contribute with code, ideas and you can even [donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C) 🥰

### 👑 Discover Nim language
<strong>What's Nim?</strong> Nim is a statically typed compiled systems programming language. It combines successful concepts from mature languages like Python, Ada and Modula. [Find out more about Nim language](https://nim-lang.org/)

<strong>Why Nim?</strong> Performance, fast compilation and C-like freedom. We want to keep code clean, readable, concise, and close to our intention. Also a very good language to learn in 2022.

### 🎩 License
Illustration of Tim Berners-Lee [made by Kagan McLeod](https://www.kaganmcleod.com).<br><br>
This is an Open Source Software released under `MIT` license. [Developed by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2022 OpenPeep & Contributors &mdash; All rights reserved.
