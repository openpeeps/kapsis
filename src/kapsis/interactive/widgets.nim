import std/[terminal, strformat]

proc promptInteractive*(question: string, answers: openArray[string], width: Positive = 80, activeIcon = " "): int =
  ## Terminal prompt that asks a `question` and returns only one of the answers from possible `answers`.
  ##
  ## .. code-block:: Nim
  ##   echo promptInteractive("is Schrödinger's Cat alive?", ["yes", "no", "maybe"])
  ##
  # Adapted from Nimble source code to stdlib, adding width optional argument.
  assert question.len > 0, "Question must not be empty"
  assert answers.len > 0, "There must be at least one possible answer"
  stdout.styledWriteLine(styleBright, question)
  var
    current = 0
    selected = false
  # Incase the cursor is at the bottom of the terminal
  for arg in answers:
    stdout.write "\n"
  # Reset the cursor to the start of the selection prompt
  cursorUp(stdout, answers.len)
  # cursorForward(stdout, width)
  hideCursor(stdout)

  # The selection loop
  while not selected:
    setForegroundColor(fgDefault)
    # Loop through the options
    for i, arg in answers:
      # Check if the option is the current
      if i == current:
        stdout.styledWrite(activeIcon & " " & arg, {styleBright, styleUnderscore})
      else:
        stdout.styledWrite("   " & arg, {styleDim})
      # Move the cursor back to the start
      cursorBackward(stdout, arg.len + 4)
      # Move down for the next item
      cursorDown(stdout)
    # Move the cursor back up to the start of the selection prompt
    cursorUp(stdout, answers.len)
    resetAttributes(stdout)

    # Ensure that the screen is updated before input
    flushFile(stdout)
    # Begin key input
    while true:
      case getch():
      of '\t', '\x1B':
        current = (current + 1) mod answers.len
        break
      of '\r', ' ':
        selected = true
        break
      of '\3':
        for i in 0 ..< answers.len:
          eraseLine(stdout)
        cursorUp(stdout) # move back to question line
        eraseLine(stdout) # erase the question line
        showCursor(stdout)
        return -1
      else: discard

  # Erase all lines of the selection
  for i in 0 ..< answers.len:
    eraseLine(stdout)
    cursorDown(stdout)
  # move the cursor back up to the initial selection line
  cursorUp(stdout, answers.len + 1)
  eraseLine(stdout)
  showCursor(stdout)
  result = current
