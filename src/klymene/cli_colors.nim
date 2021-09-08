import macros, tables, terminal

# Klymene is a fancy nymph CLI framework written in Nim,
# and helps developers creating beautiful command line interfaces.
# 
# Copyright (C) 2021 George Lemon <georgelemon@protonmail.com>
# https://github.com/icyphox/fab/blob/master/src/fab.nim

template cliEcho*(s: string, fg: ForegroundColor, style: set[Style] = {}, nl = true, lightFg = false) =
    setForeGroundColor(fg, lightFg)
    # Todo replace writeStyled with styledWriteLine/styledWrite or styledEcho
    # https://nim-lang.org/docs/terminal.html
    s.writeStyled(style)
    resetAttributes()
    if nl: echo ""

# colors
proc blue*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to blue
    cliEcho(s, fgBlue, sty, nl)

proc yellow*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to yellow
    cliEcho(s, fgYellow, sty, nl)

proc green*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to green
    cliEcho(s, fgGreen, sty, nl)

proc red*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to red
    cliEcho(s, fgRed, sty, nl)

proc white*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to white
    cliEcho(s, fgWhite, sty, nl)

proc purple*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to purple
    cliEcho(s, fgMagenta, sty, nl)

proc cyan*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to cyan
    cliEcho(s, fgCyan, sty, nl)

proc black*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to black
    cliEcho(s, fgBlack, sty, nl)

proc grey*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to grey
    cliEcho(s, fgBlack, sty, nl, lightFg = true)

proc orange*(s: string, sty: set[Style] = {}, nl = true) =
    ## Set output color to orange
    cliEcho(s, fgYellow, sty, nl, lightFg = true)

# styles
proc bold*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to bold
    cliEcho(s, fg, {styleBright} + sty, nl)

proc italic*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to italic
    cliEcho(s, fg, {styleItalic} + sty, nl)

proc reverse*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to reversed (One of the most useless thing)
    cliEcho(s, fg, {styleReverse} + sty, nl)

proc under*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to underline
    cliEcho(s, fg, {styleUnderscore} + sty, nl)

proc blink*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to blink mode
    cliEcho(s, fg, {styleBlink} + sty, nl)

proc dim*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    ## Set output text to dimmed mode
    cliEcho(s, fg, {styleDim} + sty, nl)

proc hidden*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    # Print hidden styled text
    cliEcho(s, fg, {styleHidden} + sty, nl)

# labels
proc cliLabelEcho*(label: string; lFg: ForegroundColor; s: string; sFg: ForegroundColor; styleSet: set[Style] = {}; newline = true; brightFg = false) =
    cliEcho(label, lFg, styleSet, false, brightFg)
    stdout.write(" ")
    cliEcho(s, sFg, styleSet, false, brightFg)
    if newline:
        echo ""

proc que*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    cliLabelEcho("[?]", fgBlue, s, fg, sty, nl)

proc info*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    cliLabelEcho("[!]", fgYellow, s, fg, sty, nl)

proc bad*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    cliLabelEcho("[!]", fgRed, s, fg, sty, nl)

proc good*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    cliLabelEcho("[+]", fgGreen, s, fg, sty, nl)

proc run*(s: string; fg: ForegroundColor = fgWhite; sty: set[Style] = {}; nl = true) =
    cliLabelEcho("[~]", fgWhite, s, fg, sty, nl)


# Register new echo colors
# https://forum.nim-lang.org/t/5392
# var colors* = newTable[string, proc() {.nimcall.}]()
# macro registerColorsProc(p: untyped): untyped =
#     result = newTree(nnkStmtList, p)
#     let procName = p[0]
#     let procNameAsStr = $p[0]
  
#     result.add quote do:
#         colors.add(`procNameAsStr`, `procName`)

# # proc orange*: string {.registerColorsProc.} = echo "test"
# proc white*: string {.registerColorsProc.} = makeForeground("test")
