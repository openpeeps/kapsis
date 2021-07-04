import cli_colors

# Clymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>

# CLI helper for creating various types of stdout/stdin like
# - overall coloring                Foreground, background
# - prompting       (stdout/stdin)  Message/Question / Answer
# - confirming      (boolean type)  Message/Question accepting only boolean answers
# - simple print messages           Warning, info, sucess or error

proc prompt*(label: string, color: string = "white"): string =
    # Stdin prompter with reading the input line
    cli_colors.red(label)
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

proc printInfo*(label: string, icon: string="[!]"): string =
    # Prompt an informational CLI line prepended by an icon
    echo icon & " " & label

proc printSuccess*(label: string, icon: string="✔"): string =
    # Prompt an successfully info line prepended by an icon
    echo icon & " " & label

proc printError*(label: string, icon: string="✘"): string =
    # Prompt an error info line prepended by an icon like ✕, ☓, ✖, ✗, ✘
    echo icon & " " & label