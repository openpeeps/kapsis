# Spinny test suite.
#
# Run with `nimble test` from the repository root.

import std/os
import std/strutils
import std/unicode
import unittest

import pkg/kapsis/interactive/spinny
import pkg/kapsis/interactive/spinny/[spinners, preloaders]

suite "spinners dataset":
  test "all registered spinners are valid":
    let names = spinnerNames()
    check names.len == 71
    for name in names:
      let sp = getSpinner(name)
      check sp.frames.len > 0
      check sp.interval > 0

  test "unknown spinner raises":
    expect ValueError:
      discard getSpinner("definitely-not-a-spinner")

suite "preloaders dataset":
  test "all registered preloaders are valid":
    let names = preloaderNames()
    check names.len == 16
    for name in names:
      let sp = getPreloader(name)
      check sp.frames.len > 0
      check sp.interval > 0

  test "preloader frames share a consistent display width":
    for name in preloaderNames():
      let sp = getPreloader(name)
      let w = sp.frames[0].runeLen
      for frame in sp.frames:
        check frame.runeLen == w

  test "preloaders are boxed":
    for name in preloaderNames():
      let sp = getPreloader(name)
      check sp.frames[0][0] == '['
      check sp.frames[0][^1] == ']'

suite "lookup":
  test "newSpinny by name resolves spinners and preloaders":
    var mgr = newSpinnyManager(output = stdout, forceTty = true)
    let dots = newSpinny("loading", "dots", manager = addr mgr)
    check dots.frames == skDots.frames
    let train = newSpinny("loading", "train", manager = addr mgr)
    check train.frames == pkTrain.frames
    # "bounce" exists in both datasets; spinners win
    let bounce = newSpinny("loading", "bounce", manager = addr mgr)
    check bounce.frames == skBounce.frames

  test "unknown name raises":
    var mgr = newSpinnyManager(output = stdout, forceTty = true)
    expect ValueError:
      discard newSpinny("loading", "not-a-real-style", manager = addr mgr)

suite "rendering":
  test "animates frames and restores cursor":
    let path = getTempDir() / "spinny_animate.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var spinny = newSpinny("loading", "dots", manager = addr mgr)
    spinny.start()
    sleep(300)
    spinny.success("done")
    f.flushFile()
    f.close()

    let content = readFile(path)
    check '\r' in content
    check content.contains("\e[?25l")  # cursor hidden while animating
    check content.contains("\e[?25h")  # cursor shown after finishing
    check content.contains("✔")
    check content.contains("done")
    let dots = getSpinner("dots")
    check content.contains(dots.frames[0])
    check content.contains(dots.frames[1])
    check content.contains("loading")
    removeFile(path)

  test "setText updates the message":
    let path = getTempDir() / "spinny_settext.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var spinny = newSpinny("initial", "dots", manager = addr mgr)
    spinny.start()
    sleep(150)
    spinny.setText("updated message")
    sleep(150)
    spinny.stop()
    f.flushFile()
    f.close()

    let content = readFile(path)
    check content.contains("initial")
    check content.contains("updated message")
    check not content.contains("✔")
    removeFile(path)

  test "non-tty falls back to plain output":
    let path = getTempDir() / "spinny_nottty.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f)
    var spinny = newSpinny("loading", "dots", manager = addr mgr)
    spinny.start()
    spinny.setText("still loading")
    sleep(50)
    spinny.success("done")
    f.flushFile()
    f.close()

    let content = readFile(path)
    check not content.contains("\e[")   # no escape sequences
    check content.contains("✔")
    check content.contains("done")
    removeFile(path)

  test "multiple spinners animate concurrently":
    let path = getTempDir() / "spinny_multi.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var a = newSpinny("first", "dots", manager = addr mgr)
    var b = newSpinny("second", "line", manager = addr mgr)
    a.start()
    b.start()
    sleep(250)
    a.success("a done")
    b.error("b failed")
    f.flushFile()
    f.close()

    let content = readFile(path)
    check content.contains("✔")
    check content.contains("✖")
    check content.contains("a done")
    check content.contains("b failed")
    let dots = getSpinner("dots")
    check content.contains(dots.frames[0])
    let line = getSpinner("line")
    check content.contains(line.frames[0])
    removeFile(path)

  test "setSymbol replaces the animation":
    let path = getTempDir() / "spinny_symbol.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var spinny = newSpinny("working", "dots", manager = addr mgr)
    spinny.start()
    sleep(120)
    spinny.setSymbol("*")
    sleep(150)
    spinny.stop()
    f.flushFile()
    f.close()

    let content = readFile(path)
    check content.contains("*")
    removeFile(path)

  test "log prints a persistent line":
    let path = getTempDir() / "spinny_log.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var spinny = newSpinny("working", "dots", manager = addr mgr)
    spinny.start()
    sleep(100)
    spinny.log("note: keep going")
    sleep(150)
    spinny.success("done")
    f.flushFile()
    f.close()

    let content = readFile(path)
    check content.contains("note: keep going")
    removeFile(path)

  test "withSpinny guarantees cleanup":
    let path = getTempDir() / "spinny_with.log"
    let f = open(path, fmWrite)
    var mgr = newSpinnyManager(output = f, forceTty = true)
    var spinny = newSpinny("working", "dots", manager = addr mgr)
    withSpinny(spinny):
      sleep(200)
    check not spinny.isSpinning()
    f.flushFile()
    f.close()

    let content = readFile(path)
    check '\r' in content
    check content.contains("\e[?25h")  # cursor shown after cleanup
    removeFile(path)
