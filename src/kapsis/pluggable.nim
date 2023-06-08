import dynlib, os
import ./commands

proc initPlugins*(thread: var Thread[(Kapsis)], cli: Kapsis) =
  # createThread(thread, activatePlugins, (cli))
  # joinThread thread
  discard