<p align="center"><img src="/.github/klymene.png" width="140px" alt="Klymene - CLI Toolkit written in Nim language"><br><strong>Klymene is a fancy nymph CLI framework written in Nim. Based on [docopt package](https://github.com/docopt/docopt.nim), Klymene provides additional features, tweaks and tricks for creating beautiful and fast command line interfaces. (Work in progress)</strong></p>

# Features

- [ ] CLI Preloader
- [ ] CLI Progress bar
- [x] Confirmation Prompt
- [x] Regular Prompt
- [x] Dropdown Prompt
- [x] Secret Prompt
- [x] Execute Shell Commands
- [x] Command description using `#` tag
- [x] Command separators using `___` tag

# Example from Psy
The option parser is generated based on the docstring below and passed to `Klymene` function. `Klymene` parses the usage pattern (`"Usage: ..."`) and option descriptions (lines starting with dash "`-`") and ensures that the program invocation matches the usage pattern; it parses options, arguments and commands based on that. The basic idea is that *a good help message has all necessary information in it to make a parser*.

The following Usage example is taken from Psy, a fast Package Manager for PHP environment.

```bash
🌀 Psy Package Manager (0.1.0) for PHP development & production environments.
👉 For updates, check https://github.com/openpeep/psypac

Usage:
   init                           Init a new PHP project to current location
   create <project> <template>    Create a PHP project from templates available in global repository

   search <package>               Search for a package in global repository
   clone <package>...             Clone one or more packages from a remote source
   add <package>...               Add one or more dependencies to your project
   remove <package>...            Remove one or more dependencies from your project
   delete <package>               Delete a package from disk stored in global repository

   serve <port> <file>            Invoke built-in PHP server for development, testing or demos
   stop <port>                    Stop a PHP server running on given PORT

   set env (dev|prod)             Convert PHP class map rules to PSR-4/PSR-0 or opposite
   set api (gh|gl|bb) <token>     Set your API Channel from GitHub, GitLab or BitBucket

   get api                        Get current API channel
   get env                        Get environment of the current project (dev or prod)
   get stats                      Get statistics about installations, usage and other geek stuff

   make cv                        Create a CV with your profile based on stats
   make composable                Generate a composer.json from current psy.yml project

   flush (zips|pkgs|templates)    Permanently delete files by category from global repository

Options:
  -h --help                       Show this screen.
  -v --version                    Show version.
```


Documentation
-------------

```nim
proc Klymene(doc: string, argv: seq[string] = nil,
            help = true, version: string = nil,
            optionsFirst = false, quit = true): Table[string, Value]
```

`Klymene` takes 1 required and 5 optional arguments:

- `doc` is a string that contains a **help message** that will be parsed to create the option parser. The simple rules of how to write such a help message are described at [docopt.org][]. Here is a quick example of such a string:

        Usage: my_program [-hso FILE] [--quiet | --verbose] [INPUT ...]

        -h --help    show this
        -s --sorted  sorted output
        -o FILE      specify output file [default: ./test.txt]
        --quiet      print less text
        --verbose    print more text

- `argv` is an optional argument vector; by default `Klymene` uses the argument vector passed to your program (`commandLineParams()`). Alternatively you can supply a list of strings like `@["--verbose", "-o", "hai.txt"]`.

- `help`, by default `true`, specifies whether the parser should automatically print the help message (supplied as `doc`) and terminate, in case `-h` or `--help` option is encountered (options should exist in usage pattern). If you want to handle `-h` or `--help` options manually (as other options), set `help = false`.

- `version`, by default `nil`, is an optional argument that specifies the version of your program. If supplied, then, (assuming `--version` option is mentioned in usage pattern) when parser encounters the `--version` option, it will print the supplied version and terminate. `version` can be any string, e.g. `"2.1.0rc1"`.
  > Note, when `clyemene` is set to automatically handle `-h`, `--help` and `--version` options, you still need to mention them in usage pattern for this to work. Also, for your users to know about them.

- `optionsFirst`, by default `false`. If set to `true` will disallow mixing options and positional arguments. I.e. after first positional argument, all arguments will be interpreted as positional even if the look like options. This can be used for strict compatibility with POSIX, or if you want to dispatch your arguments to other programs.

- `quit`, by default `true`, specifies whether [`quit()`][quit] should be called after encountering invalid arguments or printing the help message (see `help`). Setting this to `false` will allow `Klymene` to raise a `KlymeneExit` exception (with the `usage` member set) instead.

If the `doc` string is invalid, `KlymeneLanguageError` will be raised.

The **return** value is a [`Table`][table] with options, arguments and commands as keys, spelled exactly like in your help message. Long versions of options are given priority. For example, if you invoke the top example as:

    naval_fate ship Guardian move 100 150 --speed=15

the result will be:

```nim
{"--drifting": false,     "mine": false,
 "--help": false,         "move": true,
 "--moored": false,       "new": false,
 "--speed": "15",         "remove": false,
 "--version": false,      "set": false,
 "<name>": @["Guardian"], "ship": true,
 "<x>": "100",            "shoot": false,
 "<y>": "150"}
```

Note that this is not how the values are actually stored, because a `Table` can hold values of only one type. For that reason, a variant `Value` type is needed. `Value`'s only accessible member is `kind: ValueKind` (which shouldn't be needed anyway, because it is known beforehand). `ValueKind` is one of:

- `vkNone` (No value)

  This kind of `Value` appears when there is an option which hasn't been set and has no default. It is `false` when converted `toBool`.

- `vkBool` (A boolean)

  This represents whether a boolean flag has been set or not. Just use it in a boolean context (conversion `toBool` is present).

- `vkInt` (An integer)

  An integer represents how many times a flag has been repeated (if it is possible to supply it multiple times). Use `value.len` to obtain this `int`, or just use the value in a boolean context to find out whether this flag is present at least once.

- `vkStr` (A string)

  Any option that has a user-supplied value will be represented as a `string` (conversion to integers, etc, does not happen). To obtain this string, use `$value`.

- `vkList` (A list of strings)

  Any value that can be supplied multiple times will be represented by a `seq[string]`, even if the user provides just one. To obtain this `seq`, use `@value`. To obtain its length, use `value.len` or `@value.len`. To obtain the n-th value (0-indexed), both `value[i]` and `@value[i]` will work. If you are sure there is exactly one value, `$value` is the same as `value[0]`.

Note that you can use any kind of value in a boolean context and convert any value to `string`.

Look [in the source code](src/Klymene/value.nim) to find out more about these conversions.


Examples
--------

See [examples](examples) folder.

For more examples of docopt language see [docopt.py examples][].


Installation
------------

    nimble install docopt

This library has no dependencies outside the standard library. An impure [`re`][re] library is used.


[docopt.org]: http://docopt.org/
[docopt.py]: https://github.com/docopt/docopt
[docopt.py examples]: https://github.com/docopt/docopt/tree/master/examples
[nim]: http://nim-lang.org/
[re]: https://nim-lang.org/docs/re.html
[table]: https://nim-lang.org/docs/tables.html
[quit]: https://nim-lang.org/docs/system.html#quit%2Cint
