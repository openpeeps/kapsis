# include std/terminal
# import ./interactive/colors

import std/[macros, terminal]
import pkg/valido

import pkg/[termstyle, nancy]
import ./interactive/[spinny, spinny/spinners]
export nancy, spinny, spinners, termstyle

# include std/terminalstyledEchoProcessArg

from std/strutils import `%`, spaces, indent
export ForegroundColor, BackgroundColor

export `%`

const BR = ""
type
  Span* = tuple[text: string, fg: ForegroundColor, bg: BackgroundColor, indentSize: int]
  Row* = seq[Span]
  KapsisInputValue* = object of CatchableError

proc span*(label: string, fg = fgDefault, bg = bgDefault, indentSize = 1): Span =
  result = (label, fg, bg, indentSize)

proc blue*(label: string, indentSize = 1): Span =
  result = (label, fgBlue, bgDefault, indentSize)

proc yellow*(label: string, indentSize = 1): Span =
  result = (label, fgYellow, bgDefault, indentSize)

proc green*(label: string, indentSize = 1): Span =
  result = (label, fgGreen, bgDefault, indentSize)

proc http(ssl: bool): string =
  result = if ssl: "https://" else: "http://"

proc url*(uri: string, port: int = 0, ssl = false): Span =
  if port == 0:
    result = (http(ssl) & uri, fgDefault, bgDefault, 1)
  else:
    result = (http(ssl) & uri & ":" & $port, fgDefault, bgDefault, 1)

proc toggle*(onOff: bool): Span =
  result =
    if onOff:
      (" ON ", fgDefault, bgGreen, 1)
    else:
      (" OFF ", fgDefault, bgRed, 1)

proc display*(spans: varargs[Span]) = 
  var k = 0
  for span in spans:
    if k != 0:
      write stdout, spaces(span.indentSize)
    stdout.setBackgroundColor(span.bg)
    stdout.setForegroundColor(span.fg)
    write(stdout, span.text)
    stdout.resetAttributes()
    inc k
  write(stdout, "\n")

proc display*(spans: seq[Span]) = 
  var k = 0
  for span in spans:
    # if k != 0:
    write stdout, spaces(span.indentSize)
    stdout.setBackgroundColor(span.bg)
    stdout.setForegroundColor(span.fg)
    write(stdout, span.text)
    stdout.resetAttributes()
    inc k
  write(stdout, "\n")

proc toString*(spans: seq[Span]): string =
  ## Returns stringified `spans`
  var k = 0
  for span in spans:
    add result, spaces(span.indentSize)
    stdout.setBackgroundColor(span.bg)
    stdout.setForegroundColor(span.fg)
    write(stdout, span.text)
    stdout.resetAttributes()
    inc k
  write(stdout, "\n")

iterator rows*(items: seq[Row]): Row =
  for item in items:
    yield item

proc display*(i: int, spans: varargs[Span]) = 
  var k = 0
  write(stdout, indent("", i))
  spans.display()

proc display*(label: string, indent=0, br="") =
  ## Display a single line in one color
  var text: string
  if indent == 0: text = label
  else: text = label.indent(indent)

  if br == "before" or br == "both": echo BR  # add a new line before label
  display span(text)
  if br == "after" or br == "both": echo BR   # add a new line after label

proc displayInfo*(x: string) = 
  ## Display ``info`` label with a predefined icon and color
  display(span("Info:", fgCyan), span(x))

proc displaySuccess*(x: string) = 
  ## Display ``success`` label with a predefined icon and color
  display(span("Success:", fgGreen), span(x))

proc displayWarning*(x: string) =
  ## Display ``warning`` label with a predefined icon and color
  display(span("Warning:", fgYellow), span(x))

proc displayError*(x: string, quitProcess = false) =
  ## Display ``error` label with a predefined icon and color
  display(span("Error:", fgRed), span(x))
  if quitProcess:
    quit()

proc prompt*(label: string, color: string = "white", default=""): string =
  ## Prompt a question line and retrieve the input
  if default.len > 0:
    display(span(label), span("(" & default & ")", fgCyan))
  else:
    display(label)
  result = stdin.readLine()
  if default.len != 0 and result.len == 0:
    return default

proc promptSecret*(label: string, color:string="white", required=true): string =
  ## Prompt a hidden field and read from secret input
  display(label)
  result = readPasswordFromStdin()
  if result.len == 0 and required == true:
    return promptSecret(label, required=true)

proc promptConfirm*(label: string, icon: string="👉"): bool =
  ## Prompt a confirmation label that allows only boolean input values as follows:
  ##      Positive: ``1``, ``yes``, ``True``, ``TRUE``, ``YES``, ``Yes``, ``y``, ``Y``
  ##      Negative: ``0``, ``no``, ``False``, ``FALSE``, ``NO``, ``No``, ``n``, ``N``
  let answer = prompt(label)
  case answer:
  of "true", "1", "yes", "True", "TRUE", "YES", "Yes", "y", "Y":
      result = true
  of "false", "0", "no", "False", "FALSE", "NO", "No", "n", "N":
      result =  false
  else:
      result = promptConfirm(label)

proc askEmail*(label: string, default = "", skippable = false): string =
  ## Prompt for a valid email address. Set `skippable` true
  ## to skip empty values
  if skippable:
    result = prompt(label, default = default)
    if result.len > 0 and result.isEmail == false:
      raise newException(KapsisInputValue, "Invalid value: " & result)
  else:
    result = prompt(label, default = default)
    while not result.isEmail:
      displayError("Invalid value: " & result)
      result = askEmail(label, default)

proc askIP4*(label: string, default = "", skippable = false): string =
  ## Prompt for a valid IPv4. Use `skippable` to skip empty values
  if skippable:
    result = prompt(label, default = default)
    if result.len > 0 and result.isIP4 == false:
      raise newException(KapsisInputValue, "Invalid value: " & result)
  else:
    result = prompt(label, default = default)
    while not result.isEmail:
      displayError("Invalid value: " & result)
      result = askIP4(label, default)
