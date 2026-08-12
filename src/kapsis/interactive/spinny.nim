import std/[os, terminal, times, monotimes, strutils, locks, exitprocs, tables]
import pkg/threading/channels

import ./spinny/[colorize, spinners, preloaders]

export colorize, spinners, preloaders

const
  MaxSpinners = 16
  MaxLineLen = 512

type
  SpinnyColor* = enum
    cDefault, cBlack, cRed, cGreen, cYellow, cBlue, cMagenta, cCyan, cWhite, cGray

  SpinnyMsgKind = enum
    Stop, Success, Error, Warn, Info,
    TextChange, SymbolChange, ColorChange,
    SpinnerChange, PreloaderChange, IntervalChange

  SpinnyMsg = object
    kind: SpinnyMsgKind
    payload: string
    frames: seq[string]
    interval: int

  SpinnyState* = enum
    stIdle, stSpinning, stStopped, stSucceeded, stFailed, stWarned, stInformed

  SpinnySlot = object
    line: array[MaxLineLen, char]
    len: int

  SpinnyManager* = object
    ## Owns the terminal. All active spinners share one manager so they can be
    ## rendered on separate lines, one above the other.
    lock: Lock
    slots: array[MaxSpinners, SpinnySlot]
    count: int
    output: File
    tty: bool
    cursorHidden: bool

  Spinny* = object
    text*: string
    frames*: seq[string]
    interval*: int
    trackTime: bool
    symbol: string
    customSymbol: bool
    symbolColor: proc(x: string): string
    color: SpinnyColor
    started: bool
    state: SpinnyState
    manager: ptr SpinnyManager
    chan: Chan[SpinnyMsg]
    thread: Thread[SpinnyArgs]

  SpinnyArgs = object
    chan: ptr Chan[SpinnyMsg]
    manager: ptr SpinnyManager
    text: string
    frames: seq[string]
    interval: int
    trackTime: bool
    customSymbol: bool
    symbol: string
    color: SpinnyColor

  RenderState = object
    text: string
    frames: seq[string]
    interval: int
    customSymbol: bool
    symbol: string
    color: SpinnyColor
    frameIdx: int

var spinnyDefaultManager: SpinnyManager
var spinnyDefaultManagerInit = false

proc newSpinnyManager*(output: File = stdout, forceTty = false): SpinnyManager =
  ## Creates a terminal manager. When `forceTty` is set, animations are enabled
  ## even if `output` is not a terminal (useful for tests).
  result = SpinnyManager(output: output, tty: forceTty or output.isatty())
  initLock(result.lock)

proc defaultManager*(): ptr SpinnyManager =
  ## Returns the process-wide default terminal manager
  if not spinnyDefaultManagerInit:
    spinnyDefaultManagerInit = true
    spinnyDefaultManager.output = stdout
    spinnyDefaultManager.tty = stdout.isatty()
    initLock(spinnyDefaultManager.lock)
  addr spinnyDefaultManager

# ---------------------------------------------------------------------------
# color helpers
# ---------------------------------------------------------------------------

proc colorize(s: string, c: SpinnyColor): string =
  case c
  of cDefault: s
  of cBlack: s.fgBlack
  of cRed: s.fgRed
  of cGreen: s.fgGreen
  of cYellow: s.fgYellow
  of cBlue: s.fgBlue
  of cMagenta: s.fgMagenta
  of cCyan: s.fgCyan
  of cWhite: s.fgWhite
  of cGray: s.fgLightGray

proc statusLine(kind: SpinnyMsgKind, payload: string): string =
  ## Composes the final status line for terminal messages
  case kind
  of Success:
    result = "✔".bold.fgGreen
    if payload.len > 0: result &= " " & payload.bold.fgGreen
  of Error:
    result = "✖".bold.fgRed
    if payload.len > 0: result &= " " & payload.bold.fgRed
  of Warn:
    result = "⚠".bold.fgYellow
    if payload.len > 0: result &= " " & payload.bold.fgYellow
  of Info:
    result = "ℹ".bold.fgCyan
    if payload.len > 0: result &= " " & payload.bold.fgCyan
  else:
    discard

proc plainLine(kind: SpinnyMsgKind, payload: string): string =
  ## Plain, uncolored status line for non-terminal output
  case kind
  of Success: result = "✔"
  of Error: result = "✖"
  of Warn: result = "⚠"
  of Info: result = "ℹ"
  else: discard
  if payload.len > 0:
    if result.len > 0: add result, " "
    add result, payload

# ---------------------------------------------------------------------------
# manager primitives (all require the manager lock to be held)
# ---------------------------------------------------------------------------

proc storeLine(manager: ptr SpinnyManager, idx: int, line: string) =
  let n = min(line.len, MaxLineLen)
  if n > 0:
    copyMem(addr(manager.slots[idx].line[0]), unsafeAddr(line[0]), n)
  manager.slots[idx].len = n

proc drawAll(manager: ptr SpinnyManager) =
  ## Redraws every active spinner line relative to the current cursor position
  for i in 0 ..< manager.count:
    let up = manager.count - i
    write(manager.output, "\r")
    cursorUp(manager.output, up)
    eraseLine(manager.output)
    let slot = manager.slots[i]
    if slot.len > 0:
      discard writeBuffer(manager.output, addr(slot.line[0]), slot.len)
    cursorDown(manager.output, up)
  write(manager.output, "\r")
  flushFile(manager.output)

# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------

proc composeLine(rs: RenderState, trackTime: bool, startTime: MonoTime): string =
  var frame: string
  if rs.customSymbol:
    frame = rs.symbol
  elif rs.frames.len > 0:
    frame = rs.frames[rs.frameIdx mod rs.frames.len]
  if rs.color != cDefault:
    frame = colorize(frame, rs.color)
  result = frame
  if trackTime:
    let elapsed = getMonoTime() - startTime
    add result, " " & int(elapsed.inMinutes()).intToStr(2) & ":" & int(elapsed.inSeconds()).intToStr(2)
  if rs.text.len > 0:
    add result, " " & rs.text

proc handleMsg(rs: var RenderState, m: SpinnyMsg): bool =
  ## Applies a message to the local render state. Returns `false` when the
  ## render loop should stop.
  case m.kind
  of TextChange:
    rs.text = m.payload
  of SymbolChange:
    rs.customSymbol = true
    rs.symbol = m.payload
  of ColorChange:
    try:
      rs.color = parseEnum[SpinnyColor](m.payload)
    except ValueError:
      discard
  of SpinnerChange, PreloaderChange:
    if m.frames.len > 0:
      rs.frames = m.frames
      rs.interval = max(1, m.interval)
      rs.customSymbol = false
      rs.frameIdx = 0
  of IntervalChange:
    try:
      rs.interval = max(1, parseInt(m.payload))
    except ValueError:
      discard
  of Stop, Success, Error, Warn, Info:
    return false
  result = true

proc spinnyLoop(args: SpinnyArgs) {.thread.} =
  let manager = args.manager
  let trackTime = args.trackTime
  let startTime = getMonoTime()

  var rs = RenderState(
    text: args.text,
    frames: args.frames,
    interval: max(1, args.interval),
    customSymbol: args.customSymbol,
    symbol: args.symbol,
    color: args.color,
    frameIdx: 0
  )

  # register with the manager and draw the first frame
  acquire(manager.lock)
  if manager.count >= MaxSpinners:
    release(manager.lock)
    # too many concurrent spinners: drain so the owner never blocks on send
    var drain: SpinnyMsg
    while args.chan[].tryRecv(drain):
      discard
    return
  let slotIdx = manager.count
  inc manager.count
  if not manager.cursorHidden:
    hideCursor(manager.output)
    manager.cursorHidden = true
  storeLine(manager, slotIdx, composeLine(rs, trackTime, startTime))
  drawAll(manager)
  release(manager.lock)

  var
    next = getMonoTime() + initDuration(milliseconds = rs.interval)
    running = true
    finalKind: SpinnyMsgKind = Stop
    finalText = ""

  while running:
    var m: SpinnyMsg
    while args.chan[].tryRecv(m):
      if not handleMsg(rs, m):
        finalKind = m.kind
        finalText = m.payload
        running = false
        break
    if not running:
      break

    let now = getMonoTime()
    let remaining = (next - now).inMilliseconds
    if remaining > 0:
      sleep(remaining)

    rs.frameIdx = (rs.frameIdx + 1) mod max(1, rs.frames.len)
    acquire(manager.lock)
    storeLine(manager, slotIdx, composeLine(rs, trackTime, startTime))
    drawAll(manager)
    release(manager.lock)

    next = getMonoTime() + initDuration(milliseconds = rs.interval)

  # remove ourselves, reflow the remaining spinners and emit the final line
  acquire(manager.lock)
  for i in slotIdx ..< manager.count - 1:
    manager.slots[i] = manager.slots[i + 1]
  dec manager.count
  drawAll(manager)

  if finalKind != Stop:
    write(manager.output, "\r")
    eraseLine(manager.output)
    write(manager.output, statusLine(finalKind, finalText))
    write(manager.output, "\n")
    flushFile(manager.output)

  if manager.count == 0 and manager.cursorHidden:
    showCursor(manager.output)
    manager.cursorHidden = false
  release(manager.lock)

# ---------------------------------------------------------------------------
# public API
# ---------------------------------------------------------------------------

proc newSpinny*(text: string, s: Spinner, time = false,
                manager: ptr SpinnyManager = defaultManager()): Spinny =
  ## Creates a new spinner/preloader from a `Spinner` definition
  if s.frames.len == 0:
    raise newException(ValueError, "Spinny requires a spinner with at least one frame")
  result = Spinny(
    text: text,
    frames: s.frames,
    interval: max(1, s.interval),
    trackTime: time,
    color: cDefault,
    started: false,
    state: stIdle,
    manager: manager
  )
  result.chan = newChan[SpinnyMsg](16)

proc newSpinny*(text: string, name: string, time = false,
                manager: ptr SpinnyManager = defaultManager()): Spinny =
  ## Creates a spinner/preloader by name (e.g. `"dots"` or `"train"`)
  result =
    if spinnerByName.hasKey(name): newSpinny(text, getSpinner(name), time, manager)
    elif preloaderByName.hasKey(name): newSpinny(text, getPreloader(name), time, manager)
    else: raise newException(ValueError, "Unknown spinner or preloader: " & name)

proc sendMsg(spinny: var Spinny, kind: SpinnyMsgKind, payload = "",
             frames: seq[string] = @[], interval = 0) =
  spinny.chan.send(SpinnyMsg(kind: kind, payload: payload,
                             frames: frames, interval: interval))

proc start*(spinny: var Spinny) =
  ## Starts animating the spinner on its own line
  if spinny.started:
    raise newException(ValueError, "Spinny is already running")
  spinny.started = true
  spinny.state = stSpinning
  if not spinny.manager.tty:
    return
  var args = SpinnyArgs(
    chan: addr spinny.chan,
    manager: spinny.manager,
    text: spinny.text,
    frames: spinny.frames,
    interval: max(1, spinny.interval),
    trackTime: spinny.trackTime,
    customSymbol: spinny.customSymbol,
    symbol: spinny.symbol,
    color: spinny.color
  )
  createThread(spinny.thread, spinnyLoop, args)

proc isSpinning*(spinny: var Spinny): bool =
  spinny.started

proc setText*(spinny: var Spinny, text: string) =
  ## Updates the message shown next to the spinner
  spinny.text = text
  if spinny.started and spinny.manager.tty:
    spinny.sendMsg(TextChange, text)

proc setSymbol*(spinny: var Spinny, symbol: string) =
  ## Replaces the animated frames with a static symbol
  spinny.symbol = symbol
  spinny.customSymbol = true
  if spinny.started and spinny.manager.tty:
    var colored = symbol
    if not spinny.symbolColor.isNil:
      colored = spinny.symbolColor(symbol)
    spinny.sendMsg(SymbolChange, colored)

proc setSymbolColor*(spinny: var Spinny, color: proc(x: string): string) =
  ## Colors the static symbol (applied on the next `setSymbol` or immediately)
  spinny.symbolColor = color
  if spinny.customSymbol and spinny.started and spinny.manager.tty:
    spinny.sendMsg(SymbolChange, color(spinny.symbol))

proc setColor*(spinny: var Spinny, color: SpinnyColor) =
  ## Colors the animated frames
  spinny.color = color
  if spinny.started and spinny.manager.tty:
    spinny.sendMsg(ColorChange, $color)

proc setSpinner*(spinny: var Spinny, name: string) =
  ## Switches the animation to a spinner by name
  let sp = getSpinner(name)
  if spinny.started and spinny.manager.tty:
    spinny.sendMsg(SpinnerChange, frames = sp.frames, interval = max(1, sp.interval))
  else:
    spinny.frames = sp.frames
    spinny.interval = max(1, sp.interval)

proc setPreloader*(spinny: var Spinny, name: string) =
  ## Switches the animation to a preloader by name
  let sp = getPreloader(name)
  if spinny.started and spinny.manager.tty:
    spinny.sendMsg(PreloaderChange, frames = sp.frames, interval = max(1, sp.interval))
  else:
    spinny.frames = sp.frames
    spinny.interval = max(1, sp.interval)

proc setInterval*(spinny: var Spinny, ms: int) =
  ## Sets the animation interval in milliseconds
  spinny.interval = max(1, ms)
  if spinny.started and spinny.manager.tty:
    spinny.sendMsg(IntervalChange, $spinny.interval)

proc log*(spinny: var Spinny, text: string) =
  ## Prints a persistent line below the active spinners
  if spinny.manager.tty:
    acquire(spinny.manager.lock)
    write(spinny.manager.output, "\r")
    eraseLine(spinny.manager.output)
    write(spinny.manager.output, text)
    write(spinny.manager.output, "\n")
    flushFile(spinny.manager.output)
    release(spinny.manager.lock)
  else:
    write(spinny.manager.output, text)
    write(spinny.manager.output, "\n")
    flushFile(spinny.manager.output)

proc finish(spinny: var Spinny, kind: SpinnyMsgKind, payload = "") =
  if not spinny.started:
    raise newException(ValueError, "Spinny is not running")
  if not spinny.manager.tty:
    spinny.started = false
    case kind
    of Stop: spinny.state = stStopped
    of Success: spinny.state = stSucceeded
    of Error: spinny.state = stFailed
    of Warn: spinny.state = stWarned
    of Info: spinny.state = stInformed
    else: discard
    if kind != Stop:
      write(spinny.manager.output, plainLine(kind, payload))
      write(spinny.manager.output, "\n")
      flushFile(spinny.manager.output)
    return
  spinny.sendMsg(kind, payload)
  joinThread(spinny.thread)
  spinny.started = false
  case kind
  of Stop: spinny.state = stStopped
  of Success: spinny.state = stSucceeded
  of Error: spinny.state = stFailed
  of Warn: spinny.state = stWarned
  of Info: spinny.state = stInformed
  else: discard

proc stop*(spinny: var Spinny) =
  ## Stops the spinner and clears its line
  spinny.finish(Stop)

proc success*(spinny: var Spinny, msg = "") =
  ## Stops the spinner with a green checkmark status line
  spinny.finish(Success, msg)

proc error*(spinny: var Spinny, msg = "") =
  ## Stops the spinner with a red cross status line
  spinny.finish(Error, msg)

proc warn*(spinny: var Spinny, msg = "") =
  ## Stops the spinner with a yellow warning status line
  spinny.finish(Warn, msg)

proc info*(spinny: var Spinny, msg = "") =
  ## Stops the spinner with a cyan info status line
  spinny.finish(Info, msg)

template withSpinny*(spinny: Spinny, body: untyped): untyped =
  ## Runs `body` while the spinner is animating, guaranteeing cleanup
  spinny.start()
  try:
    body
  finally:
    if spinny.isSpinning():
      spinny.stop()

proc cleanupSpinny() =
  ## Restores the terminal (shows the cursor) on process exit
  if spinnyDefaultManagerInit:
    acquire(spinnyDefaultManager.lock)
    if spinnyDefaultManager.cursorHidden:
      showCursor(spinnyDefaultManager.output)
      spinnyDefaultManager.cursorHidden = false
    release(spinnyDefaultManager.lock)

addExitProc(cleanupSpinny)
