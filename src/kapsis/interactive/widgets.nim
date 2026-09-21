import std/[terminal, strformat, sequtils]

proc eraseSelection(answersLen: int) =
  ## Erases the rendered selection lines and restores the cursor.
  for i in 0 ..< answersLen:
    eraseLine(stdout)
    cursorDown(stdout)
  cursorUp(stdout, answersLen + 1)
  eraseLine(stdout)
  showCursor(stdout)

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
    when defined(windows):
      setForegroundColor(fgWhite)
    else:
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
  eraseSelection(answers.len)
  result = current

proc promptCheckbox*(question: string, answers: openArray[string], preselected: openArray[int] = [],
    width: Positive = 80, activeIcon = ">", checkedIcon = "[x]", uncheckedIcon = "[ ]"): seq[int] =
  ## Terminal checkbox prompt that looks like `promptInteractive`
  ## but allows toggling multiple answers with `Space`.
  ##
  ## Navigation: `Up`/`Down` (or `k`/`j`, `Tab` for next), `Space` toggles
  ## the current answer, `Enter` confirms, `a` selects all, `n` clears,
  ## `Ctrl-C` aborts and returns an empty sequence.
  ##
  ## .. code-block:: Nim
  ##   let picks = promptCheckbox("Select recipes:", ["JOSE", "Brotli", "mimedb"])
  ##
  assert question.len > 0, "Question must not be empty"
  assert answers.len > 0, "There must be at least one possible answer"
  if not isatty(stdout):
    return preselected.toSeq()
  stdout.styledWriteLine(styleBright, question)
  stdout.styledWriteLine(styleDim, "Space to toggle • Enter to confirm • a all • n none")
  let hintLines = 1
  var
    current = 0
    checked = newSeq[bool](answers.len)
    done = false
  for i in preselected:
    if i >= 0 and i < answers.len:
      checked[i] = true
  # Incase the cursor is at the bottom of the terminal
  for arg in answers:
    stdout.write "\n"
  # Reset the cursor to the start of the selection prompt
  cursorUp(stdout, answers.len)
  hideCursor(stdout)

  proc renderRow(i: int, arg: string): string =
    let cursor = if i == current: activeIcon & " " else: "  "
    let box = if checked[i]: checkedIcon & " " else: uncheckedIcon & " "
    cursor & box & arg

  # The selection loop
  while not done:
    when defined(windows):
      setForegroundColor(fgWhite)
    else:
      setForegroundColor(fgDefault)
    for i, arg in answers:
      let line = renderRow(i, arg)
      if i == current:
        stdout.styledWrite(line, {styleBright, styleUnderscore})
      else:
        stdout.styledWrite(line, {styleDim})
      cursorBackward(stdout, line.len)
      cursorDown(stdout)
    cursorUp(stdout, answers.len)
    resetAttributes(stdout)
    flushFile(stdout)

    # Begin key input
    while true:
      let ch = getch()
      case ch
      of '\r': # Enter confirms
        done = true
        break
      of ' ': # Space toggles current answer
        checked[current] = not checked[current]
        break
      of '\t': # Tab moves down
        current = (current + 1) mod answers.len
        break
      of 'j', 'J': # vim-style down
        current = (current + 1) mod answers.len
        break
      of 'k', 'K': # vim-style up
        current = (current - 1 + answers.len) mod answers.len
        break
      of 'a', 'A': # select all
        for i in 0 ..< checked.len:
          checked[i] = true
        break
      of 'n', 'N': # select none
        for i in 0 ..< checked.len:
          checked[i] = false
        break
      of '\x1B': # Esc or arrow-key sequence (Esc [ A/B)
        let second = getch()
        if second == '[':
          let third = getch()
          case third
          of 'A': current = (current - 1 + answers.len) mod answers.len
          of 'B': current = (current + 1) mod answers.len
          else: current = (current + 1) mod answers.len
        else:
          current = (current + 1) mod answers.len
        break
      of '\3': # Ctrl-C aborts with empty selection
        eraseLine(stdout)
        cursorUp(stdout) # move back to question line
        eraseLine(stdout)
        # erase the hint line too
        cursorUp(stdout)
        eraseLine(stdout)
        showCursor(stdout)
        # erase rendered rows left below cursor
        for i in 0 ..< answers.len:
          eraseLine(stdout)
          cursorDown(stdout)
        cursorUp(stdout, answers.len)
        showCursor(stdout)
        return @[]
      else: discard

  # Erase all lines of the selection (rows + hint + question)
  for i in 0 ..< answers.len:
    eraseLine(stdout)
    cursorDown(stdout)
  cursorUp(stdout, answers.len + hintLines + 1)
  for i in 0 .. hintLines:
    eraseLine(stdout)
    cursorDown(stdout)
  cursorUp(stdout, hintLines + 1)
  eraseLine(stdout)
  showCursor(stdout)
  for i, c in checked:
    if c:
      result.add(i)
