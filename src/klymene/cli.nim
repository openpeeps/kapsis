import cli_colors
import terminal

# Klymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>

# CLI helper for creating various types of stdout/stdin like
# - overall coloring                Foreground, background
# - prompting       (stdout/stdin)  Message/Question / Answer
# - confirming      (boolean type)  Message/Question accepting only boolean answers
# - simple print messages           Warning, info, sucess or error

proc display*(label: string, color: string = "white") =
    ## Stdin prompter with reading the input line
    cli_colors.white(label)

proc prompt*(label: string, color: string = "white"): string =
    ## Prompt a question line and retrieve the input
    display(label)
    let answer = stdin.readLine()
    return answer

proc promptSecret*(label: string, color:string="white"): string =
    ## Prompt a hidden field and read from secret input
    display(label)
    terminal.readPasswordFromStdin()

proc promptConfirm*(label: string, icon: string="👉"): bool =
    ## Prompt a confirmation field that allows only boolean-like values
    ## Some values accepted: 1, 0, yes, no, true, false, y, f
    ## Both lowercase and uppercase is accepted
    let answer = prompt(label)
    case answer:
    of "true", "1", "yes", "True", "TRUE", "YES", "Yes", "y", "Y":
        return true
    of "false", "0", "no", "False", "FALSE", "NO", "No", "n", "N":
        return false
    else:
        promptConfirm(label)

proc promptList*(question: string, args: openarray[string]): string =
    ## Prompt an interactive list to choose from using 'tab' key
    ## https://github.com/nim-lang/nimble/blob/master/src/nimblepkg/cli.nim
    display(question)
    # displayLegend("Select", "Cycle with 'Tab'", "'Enter' when done")

proc displayInfo*(label: string, icon: string="[!]") =
    ## Print an info line, lightblue, prepended by an icon
    display(icon & " " & label, "white")

proc displaySuccess*(label: string, icon: string="✔") =
    ## Print a success line in green, prepended by an icon
    display(icon & " " & label, "green")

proc displayError*(label: string, icon: string="✘") =
    ## Print an error line in red, prepended by an icon like ✕, ☓, ✖, ✗, ✘
    display(icon & " " & label, "red")