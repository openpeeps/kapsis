# Klymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>
# Klymene is Based on Docopt Package.
# 
# Copyright (C) 2015 Oleh Prypin <blaxpirit@gmail.com>
# Licensed under terms of MIT license (see LICENSE)
import strutils, unicode, macros, osproc, terminal, sequtils, os

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

proc cmd*(inputCmd: string, inputArgs: array): any {.discardable.} =
    ## Short hand for executing shell commands via execProcess
    return osproc.execProcess(inputCmd, args=inputArgs, options={poStdErrToStdOut, poUsePath})

proc cmdExec*(inputCmd: string, inputArgs: array): any =
    ## Short hand for executing shell commands without stdout (output)
    cmd(inputCmd, inputArgs)
    discard

proc isEmptyDir*(dir: string): bool =
    ## Detemrine if the specified directory is empty
    toSeq(walkdir dir).len == 0

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
    ## Determine if the given string contains any uppercase chars
    ## Is the string in uppercase (and there is at least one cased character)?
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
