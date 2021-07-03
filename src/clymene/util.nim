# Clymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>
# Clymene is Based on Docopt Package.
# 
# Copyright (C) 2015 Oleh Prypin <blaxpirit@gmail.com>
# Licensed under terms of MIT license (see LICENSE)
import strutils, unicode, macros
import osproc, terminal

template any_it*(lst: typed, pred: untyped): bool =
    # Does `pred` return true for any of the `it`s of `lst`?
    var result {.gensym.} = false
    for it {.inject.} in lst:
        if pred:
            result = true
            break
    result

template map_it*(lst, typ: typed, op: untyped): untyped =
    # Returns `seq[typ]` that contains `op` applied to each `it` of `lst`
    var result {.gensym.}: seq[typ] = @[]
    for it {.inject.} in items(lst):
        result.add(op)
    result

proc count*[T](s: openarray[T], it: T): int =
    # How many times this item appears in an array
    result = 0
    for x in s:
        if x == it:
            result += 1

proc cmd*(inputCmd: string, inputArgs: array): any =
    # CMD Execute shell commands via execProcess
    return osproc.execProcess(inputCmd, args=inputArgs, options={poStdErrToStdOut, poUsePath})

proc prompt*(label: string): string =
    # Stdin prompter with reading the input line
    echo label
    let answer = stdin.readLine()
    return answer

proc confirm*(label: string, icon: string="👉"): bool =
    # Confirmation Prompter showing a question and reading the input line
    case prompt(icon & " " & label):
    of "true", "1", "yes", "True", "TRUE", "YES", "Yes", "y":
        return true
    of "false", "0", "no", "False", "FALSE", "NO", "No", "n":
        return false
    else:
        confirm(label)

proc printSuccess*(label: string, icon: string="✔"): string =
    # Prompt an successfully info line prepended by an icon
    echo icon & " " & label

proc printError*(label: string, icon: string="✘"): string =
    # Prompt an error info line prepended by an icon like ✕, ☓, ✖, ✗, ✘
    echo icon & " " & label

proc partition*(s, sep: string): tuple[left, sep, right: string] =
    ## "a+b".partition("+") == ("a", "+", "b")
    ## "a+b".partition("-") == ("a+b", "", "")
    assert sep != ""
    let pos = s.find(sep)
    if pos < 0:
        (s, "", "")
    else:
        (s.substr(0, pos.pred), s.substr(pos, pos.pred+sep.len), s.substr(pos+sep.len))

proc is_upper*(s: string): bool =
    # Determine if the given string is with uppercase
    # Is the string in uppercase (and there is at least one cased character)?
    let upper = unicode.to_upper(s)
    s == upper and upper != unicode.to_lower(s)

macro gen_class*(body: untyped): untyped =
    # When applied to a type block, this will generate methods
    # that return each type's name as a string.
    for typ in body[0].children:
        var meth = "method class(self: $1): string"
        if $typ[2][0][1][0] == "RootObj":
            meth &= "{.base, gcsafe.}"
        meth &= "= \"$1\""
        body.add(parse_stmt(meth.format(typ[0])))
    body
