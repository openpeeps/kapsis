import cli_colors
import terminal
from strutils import `%`, spaces, indent

const BR = ""
# Klymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>

# CLI helper for creating various types of stdout/stdin like
# - overall coloring                Foreground, background
# - prompting       (stdout/stdin)  Message/Question / Answer
# - confirming      (boolean type)  Message/Question accepting only boolean answers
# - simple print messages           Warning, info, sucess or error

proc display*(label: string, color: string = "white", indent=0, br="") =
    ## Stdin prompter with reading the input line
    var text: string
    if indent == 0: text = label
    else: text = label.indent(indent)

    if br == "before" or br == "both": echo BR  # add a new line before label
    cli_colors.white(text)
    if br == "after" or br == "both": echo BR   # add a new line after label

proc prompt*(label: string, color: string = "white", default=""): string =
    ## Prompt a question line and retrieve the input
    display(label)
    var answer = stdin.readLine()
    if default.len != 0 and answer.len == 0:
       return default
    return answer

proc promptSecret*(label: string, color:string="white", required=true): string =
    ## Prompt a hidden field and read from secret input
    display(label)
    let inputPassword = terminal.readPasswordFromStdin()
    if inputPassword.len == 0 and required == true:
        return promptSecret(label, required=true)
    return inputPassword

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

const longestCategory = len("Downloading")

proc calculateCategoryOffset(category: string): int =
    assert category.len <= longestCategory
    return longestCategory - category.len

proc displayCategory(category: string) =
    # Calculate how much the `category` must be offset to align along a center line.
    let offset = calculateCategoryOffset(category)

    # Display the category.
    let text = "$1$2 " % [spaces(offset), category]
    # if globalCLI.showColor:
    setForegroundColor(stdout, fgWhite)
    writeStyled(text, {styleBright})
    resetAttributes()
    # else:
        # stdout.write(text)

proc promptList*(question: string, args: openarray[string]): string =
    ## Prompt an interactive list to choose from using 'tab' key
    ## https://github.com/nim-lang/nimble/blob/master/src/nimblepkg/cli.nim
    display(question)
    displayCategory("Choices:")
    var current = 0
    var selected = false
    # Incase the cursor is at the bottom of the terminal
    for arg in args:
        stdout.write "\n"
    # Reset the cursor to the start of the selection prompt
    cursorUp(stdout, args.len)
    cursorForward(stdout, longestCategory)
    hideCursor(stdout)

    # The selection loop
    while not selected:
        setForegroundColor(fgDefault)
        # Loop through the options
        for i, arg in args:
            # Check if the option is the current
            if i == current:
                writeStyled("> " & arg & " <", {styleBright})
            else:
                writeStyled("  " & arg & "  ", {styleDim})
            # Move the cursor back to the start
            for s in 0..<(arg.len + 4):
                cursorBackward(stdout)
            # Move down for the next item
            cursorDown(stdout)
        # Move the cursor back up to the start of the selection prompt
        for i in 0..<(args.len()):
            cursorUp(stdout)
        resetAttributes(stdout)

        # Ensure that the screen is updated before input
        flushFile(stdout)

        # Begin key input
        while true:
            case getch():
            of '\t':
                current = (current + 1) mod args.len
                break
            of '\r':
                selected = true
                break
            of '\3':
                showCursor(stdout)
                raise newException(Defect, "Keyboard interrupt")
            else: discard

    # Erase all lines of the selection
    for i in 0..<args.len:
        eraseLine(stdout)
        cursorDown(stdout)

    # Move the cursor back up to the initial selection line
    for i in 0..<args.len():
        cursorUp(stdout)
    showCursor(stdout)

    return args[current]

proc displayInfo*(label: string, icon: string="[!]") =
    ## Print an info line, lightblue, prepended by an icon
    display(icon & " " & label)

proc displaySuccess*(label: string, icon: string="✔") =
    ## Print a success line in green, prepended by an icon
    green(icon & " " & label)

proc displayError*(label: string, icon: string="✘") =
    ## Print an error line in red, prepended by an icon like ✕, ☓, ✖, ✗, ✘
    red(icon & " " & label)