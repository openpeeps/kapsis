import std/[os, terminal, times, monotimes, strutils]

import spinny/[colorize, spinners]
export spinners, colorize

type
  Spinny = ref object
    text: string
    running: bool
    frames: seq[string]
    frame: string
    interval: int
    customSymbol: bool
    trackTime: bool
    startTime: MonoTime

  EventKind = enum
    Stop, StopSuccess, StopError,
    SymbolChange, TextChange

  SpinnyEvent = tuple
    kind: EventKind
    payload: string

var spinnyThread: Thread[Spinny]
var spinnyChannel: Channel[SpinnyEvent]

proc newSpinny*(text: string, s: Spinner, time = false): Spinny =
  result = Spinny(
    text: text,
    running: true,
    frames: s.frames,
    customSymbol: false,
    interval: s.interval,
    trackTime: time
  )

proc setSymbolColor*(spinny: Spinny, color: proc(x: string): string) =
  for frame in spinny.frames.mitems():
    frame = color(frame)

proc setSymbol*(spinny: Spinny, symbol: string) =
  spinnyChannel.send((SymbolChange, symbol))

proc setText*(spinny: Spinny, text: string) =
  spinnyChannel.send((TextChange, text))

proc handleEvent(spinny: Spinny, eventData: SpinnyEvent): bool =
  result = true
  case eventData.kind
  of Stop:
    result = false
  of SymbolChange:
    spinny.customSymbol = true
    spinny.frame = eventData.payload
  of TextChange:
    spinny.text = eventData.payload
  of StopSuccess:
    spinny.customSymbol = true
    spinny.frame = "✔".bold.fgGreen
    spinny.text = eventData.payload.bold.fgGreen
  of StopError:
    spinny.customSymbol = true
    spinny.frame = "✖".bold.fgRed
    spinny.text = eventData.payload.bold.fgRed

proc timeDiff(d: Duration): string =
  # No hours handling - seems like an overkill :D
  let minutes = int d.inMinutes()
  let seconds = int d.inSeconds()
  result = minutes.intToStr(2) & ":" & seconds.intToStr(2)

proc spinnyLoop(spinny: Spinny) {.thread.} =
  var frameCounter = 0
  # Get the starting time before the loop
  if spinny.trackTime:
    spinny.startTime = getMonoTime()

  while spinny.running:
    let data = spinnyChannel.tryRecv()
    if data.dataAvailable:
      # If we received a Stop event
      if not spinny.handleEvent(data.msg):
        spinnyChannel.close()
        # This is required so we can reopen the same channel more than once
        # See https://github.com/nim-lang/Nim/issues/6369
        spinnyChannel = default(typeof(spinnyChannel))
        spinny.running = false

    stdout.flushFile()
    if not spinny.customSymbol:
      spinny.frame = spinny.frames[frameCounter]
    var text = spinny.text
    if spinny.trackTime:
      text = timeDiff(getMonoTime() - spinny.startTime) & " " & text

    eraseLine()
    stdout.write(spinny.frame & " " & text)
    stdout.flushFile()

    sleep(spinny.interval)

    if frameCounter >= spinny.frames.len - 1:
      frameCounter = 0
    else:
      frameCounter += 1

proc start*(spinny: Spinny) =
  if spinnyThread.running():
    # TODO: Maybe we should make this a Defect?
    raise newException(ValueError, "Previous Spinny instance wasn't stopped!")
  spinnyChannel.open()
  createThread(spinnyThread, spinnyLoop, spinny)

proc stop(spinny: Spinny, kind: EventKind, payload = "") =
  spinnyChannel.send((kind, payload))
  if kind != Stop:
    spinnyChannel.send((Stop, ""))
  joinThread(spinnyThread)
  # We need to output a newline at the end
  echo ""

proc stop*(spinny: Spinny) =
  spinny.stop(Stop)

proc success*(spinny: Spinny, msg: string) =
  spinny.stop(StopSuccess, msg)

proc error*(spinny: Spinny, msg: string) =
  spinny.stop(StopError, msg)