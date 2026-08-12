# Boxed preloaders - infinite animations rendered inside a `[...]` container.
# Squares made of `█▓▒░` and friends slide, bounce and fade forever.
# Same `Spinner` shape as the spinners dataset, so they run through the same
# Spinny machinery.

import std/[tables, algorithm]

import ./spinners

const
  pkBounce* = Spinner(interval: 80, frames: @[
      "[█      ]",
      "[ █     ]",
      "[  █    ]",
      "[   █   ]",
      "[    █  ]",
      "[     █ ]",
      "[      █]",
      "[     █ ]",
      "[    █  ]",
      "[   █   ]",
      "[  █    ]",
      "[ █     ]",
    ]
  )

  pkDualBounce* = Spinner(interval: 80, frames: @[
      "[█     █]",
      "[ █   █ ]",
      "[  █ █  ]",
      "[   █   ]",
      "[  █ █  ]",
      "[ █   █ ]",
    ]
  )

  pkPulse* = Spinner(interval: 80, frames: @[
      "[█      ]",
      "[██     ]",
      "[███    ]",
      "[████   ]",
      "[█████  ]",
      "[██████ ]",
      "[███████]",
      "[██████ ]",
      "[█████  ]",
      "[████   ]",
      "[███    ]",
      "[██     ]",
      "[█      ]",
    ]
  )

  pkDualPulse* = Spinner(interval: 80, frames: @[
      "[   █   ]",
      "[  ███  ]",
      "[ █████ ]",
      "[███████]",
      "[ █████ ]",
      "[  ███  ]",
      "[   █   ]",
    ]
  )

  pkFade* = Spinner(interval: 100, frames: @[
      "[░      ]",
      "[▒      ]",
      "[▓      ]",
      "[█      ]",
      "[▓      ]",
      "[▒      ]",
      "[░      ]",
      "[       ]",
    ]
  )

  pkFadeWave* = Spinner(interval: 80, frames: @[
      "[░      ]",
      "[▒░     ]",
      "[▓▒░    ]",
      "[█▓▒░   ]",
      "[ █▓▒░  ]",
      "[  █▓▒░ ]",
      "[   █▓▒░]",
      "[    █▓▒]",
      "[     █▓]",
      "[      █]",
    ]
  )

  pkSlide* = Spinner(interval: 70, frames: @[
      "[█ █ █  ]",
      "[ █ █ █ ]",
      "[  █ █ █]",
      "[█  █ █ ]",
      "[ █  █ █]",
      "[█ █  █ ]",
    ]
  )

  pkThreeBounce* = Spinner(interval: 80, frames: @[
      "[█ █ █  ]",
      "[ █ █ █ ]",
      "[  █ █ █]",
      "[ █ █ █ ]",
    ]
  )

  pkWave* = Spinner(interval: 90, frames: @[
      "[▁▂▃▄▅▆▇]",
      "[▂▃▄▅▆▇█]",
      "[▃▄▅▆▇█▇]",
      "[▄▅▆▇█▇▆]",
      "[▅▆▇█▇▆▅]",
      "[▆▇█▇▆▅▄]",
      "[▇█▇▆▅▄▃]",
      "[█▇▆▅▄▃▂]",
      "[▇▆▅▄▃▂▁]",
      "[▆▅▄▃▂▁▁]",
      "[▅▄▃▂▁▁▁]",
      "[▄▃▂▁▁▁▁]",
    ]
  )

  pkGrow* = Spinner(interval: 100, frames: @[
      "[█      ]",
      "[██     ]",
      "[███    ]",
      "[████   ]",
      "[█████  ]",
      "[██████ ]",
      "[███████]",
    ]
  )

  pkDots* = Spinner(interval: 100, frames: @[
      "[●       ]",
      "[●●      ]",
      "[●●●     ]",
      "[●●●●    ]",
      "[●●●●●   ]",
      "[●●●●●●  ]",
      "[●●●●●●● ]",
      "[●●●●●●●●]",
      "[ ●●●●●●●]",
      "[  ●●●●●●]",
      "[   ●●●●●]",
      "[    ●●●●]",
      "[     ●●●]",
      "[      ●●]",
      "[       ●]",
    ]
  )

  pkRing* = Spinner(interval: 120, frames: @[
      "[◴      ]",
      "[◷      ]",
      "[◶      ]",
      "[◵      ]",
    ]
  )

  pkSpinSquare* = Spinner(interval: 100, frames: @[
      "[▘      ]",
      "[▝      ]",
      "[▗      ]",
      "[▖      ]",
    ]
  )

  pkTrain* = Spinner(interval: 80, frames: @[
      "[███     ]",
      "[ ███    ]",
      "[  ███   ]",
      "[   ███  ]",
      "[    ███ ]",
      "[     ███]",
      "[███     ]",
    ]
  )

  pkSyncBounce* = Spinner(interval: 80, frames: @[
      "[█     █]",
      "[██   ██]",
      "[███ ███]",
      "[███████]",
      "[███ ███]",
      "[██   ██]",
      "[█     █]",
    ]
  )

  pkEqualizer* = Spinner(interval: 80, frames: @[
      "[▁▄▁▄▁   ]",
      "[▂▅▂▅▂   ]",
      "[▃▆▃▆▃   ]",
      "[▄▇▄▇▄   ]",
      "[▃▆▃▆▃   ]",
      "[▂▅▂▅▂   ]",
      "[▁▄▁▄▁   ]",
    ]
  )

const
  PreloaderEntries* = [
    ("bounce", pkBounce), ("dualBounce", pkDualBounce),
    ("pulse", pkPulse), ("dualPulse", pkDualPulse),
    ("fade", pkFade), ("fadeWave", pkFadeWave),
    ("slide", pkSlide), ("threeBounce", pkThreeBounce),
    ("wave", pkWave), ("grow", pkGrow),
    ("dots", pkDots), ("ring", pkRing),
    ("spinSquare", pkSpinSquare), ("train", pkTrain),
    ("syncBounce", pkSyncBounce), ("equalizer", pkEqualizer),
  ]

let
  preloaderByName* = block:
    var t: Table[string, Spinner]
    for (name, sp) in PreloaderEntries:
      t[name] = sp
    t

proc getPreloader*(name: string): Spinner =
  ## Returns the preloader matching `name` (e.g. `"bounce"`), or raises `ValueError`
  result = preloaderByName.getOrDefault(name)
  if result.frames.len == 0:
    raise newException(ValueError, "Unknown preloader: " & name)

proc preloaderNames*(): seq[string] =
  ## Returns the list of available preloader names
  for name in preloaderByName.keys:
    result.add name
  result.sort()

proc allPreloaders*(): seq[Spinner] =
  ## Returns every preloader in registry order
  for (_, sp) in PreloaderEntries:
    result.add sp
