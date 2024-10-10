# Spinners here are from https://github.com/sindresorhus/cli-spinners, it's license:
# MIT License
# Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# converted to Nim with
# https://gist.github.com/Yardanico/4137a09f171bfceae0b1dc531fdcc631
type
  Spinner* = object
    interval*: int
    frames*: seq[string]

proc makeSpinner*(interval: int, frames: openArray[string]): Spinner =
  Spinner(interval: interval, frames: @frames)

const
  skDots* = Spinner(interval: 80, frames: @[
      "⠋",
      "⠙",
      "⠹",
      "⠸",
      "⠼",
      "⠴",
      "⠦",
      "⠧",
      "⠇",
      "⠏",
    ]
  )

  skDots2* = Spinner(interval: 80, frames: @[
      "⣾",
      "⣽",
      "⣻",
      "⢿",
      "⡿",
      "⣟",
      "⣯",
      "⣷",
    ]
  )

  skDots3* = Spinner(interval: 80, frames: @[
      "⠋",
      "⠙",
      "⠚",
      "⠞",
      "⠖",
      "⠦",
      "⠴",
      "⠲",
      "⠳",
      "⠓",
    ]
  )

  skDots4* = Spinner(interval: 80, frames: @[
      "⠄",
      "⠆",
      "⠇",
      "⠋",
      "⠙",
      "⠸",
      "⠰",
      "⠠",
      "⠰",
      "⠸",
      "⠙",
      "⠋",
      "⠇",
      "⠆",
    ]
  )

  skDots5* = Spinner(interval: 80, frames: @[
      "⠋",
      "⠙",
      "⠚",
      "⠒",
      "⠂",
      "⠂",
      "⠒",
      "⠲",
      "⠴",
      "⠦",
      "⠖",
      "⠒",
      "⠐",
      "⠐",
      "⠒",
      "⠓",
      "⠋",
    ]
  )

  skDots6* = Spinner(interval: 80, frames: @[
      "⠁",
      "⠉",
      "⠙",
      "⠚",
      "⠒",
      "⠂",
      "⠂",
      "⠒",
      "⠲",
      "⠴",
      "⠤",
      "⠄",
      "⠄",
      "⠤",
      "⠴",
      "⠲",
      "⠒",
      "⠂",
      "⠂",
      "⠒",
      "⠚",
      "⠙",
      "⠉",
      "⠁",
    ]
  )

  skDots7* = Spinner(interval: 80, frames: @[
      "⠈",
      "⠉",
      "⠋",
      "⠓",
      "⠒",
      "⠐",
      "⠐",
      "⠒",
      "⠖",
      "⠦",
      "⠤",
      "⠠",
      "⠠",
      "⠤",
      "⠦",
      "⠖",
      "⠒",
      "⠐",
      "⠐",
      "⠒",
      "⠓",
      "⠋",
      "⠉",
      "⠈",
    ]
  )

  skDots8* = Spinner(interval: 80, frames: @[
      "⠁",
      "⠁",
      "⠉",
      "⠙",
      "⠚",
      "⠒",
      "⠂",
      "⠂",
      "⠒",
      "⠲",
      "⠴",
      "⠤",
      "⠄",
      "⠄",
      "⠤",
      "⠠",
      "⠠",
      "⠤",
      "⠦",
      "⠖",
      "⠒",
      "⠐",
      "⠐",
      "⠒",
      "⠓",
      "⠋",
      "⠉",
      "⠈",
      "⠈",
    ]
  )

  skDots9* = Spinner(interval: 80, frames: @[
      "⢹",
      "⢺",
      "⢼",
      "⣸",
      "⣇",
      "⡧",
      "⡗",
      "⡏",
    ]
  )

  skDots10* = Spinner(interval: 80, frames: @[
      "⢄",
      "⢂",
      "⢁",
      "⡁",
      "⡈",
      "⡐",
      "⡠",
    ]
  )

  skDots11* = Spinner(interval: 100, frames: @[
      "⠁",
      "⠂",
      "⠄",
      "⡀",
      "⢀",
      "⠠",
      "⠐",
      "⠈",
    ]
  )

  skDots12* = Spinner(interval: 80, frames: @[
      "⢀⠀",
      "⡀⠀",
      "⠄⠀",
      "⢂⠀",
      "⡂⠀",
      "⠅⠀",
      "⢃⠀",
      "⡃⠀",
      "⠍⠀",
      "⢋⠀",
      "⡋⠀",
      "⠍⠁",
      "⢋⠁",
      "⡋⠁",
      "⠍⠉",
      "⠋⠉",
      "⠋⠉",
      "⠉⠙",
      "⠉⠙",
      "⠉⠩",
      "⠈⢙",
      "⠈⡙",
      "⢈⠩",
      "⡀⢙",
      "⠄⡙",
      "⢂⠩",
      "⡂⢘",
      "⠅⡘",
      "⢃⠨",
      "⡃⢐",
      "⠍⡐",
      "⢋⠠",
      "⡋⢀",
      "⠍⡁",
      "⢋⠁",
      "⡋⠁",
      "⠍⠉",
      "⠋⠉",
      "⠋⠉",
      "⠉⠙",
      "⠉⠙",
      "⠉⠩",
      "⠈⢙",
      "⠈⡙",
      "⠈⠩",
      "⠀⢙",
      "⠀⡙",
      "⠀⠩",
      "⠀⢘",
      "⠀⡘",
      "⠀⠨",
      "⠀⢐",
      "⠀⡐",
      "⠀⠠",
      "⠀⢀",
      "⠀⡀",
    ]
  )

  skDots8Bit* = Spinner(interval: 80, frames: @[
      "⠀",
      "⠁",
      "⠂",
      "⠃",
      "⠄",
      "⠅",
      "⠆",
      "⠇",
      "⡀",
      "⡁",
      "⡂",
      "⡃",
      "⡄",
      "⡅",
      "⡆",
      "⡇",
      "⠈",
      "⠉",
      "⠊",
      "⠋",
      "⠌",
      "⠍",
      "⠎",
      "⠏",
      "⡈",
      "⡉",
      "⡊",
      "⡋",
      "⡌",
      "⡍",
      "⡎",
      "⡏",
      "⠐",
      "⠑",
      "⠒",
      "⠓",
      "⠔",
      "⠕",
      "⠖",
      "⠗",
      "⡐",
      "⡑",
      "⡒",
      "⡓",
      "⡔",
      "⡕",
      "⡖",
      "⡗",
      "⠘",
      "⠙",
      "⠚",
      "⠛",
      "⠜",
      "⠝",
      "⠞",
      "⠟",
      "⡘",
      "⡙",
      "⡚",
      "⡛",
      "⡜",
      "⡝",
      "⡞",
      "⡟",
      "⠠",
      "⠡",
      "⠢",
      "⠣",
      "⠤",
      "⠥",
      "⠦",
      "⠧",
      "⡠",
      "⡡",
      "⡢",
      "⡣",
      "⡤",
      "⡥",
      "⡦",
      "⡧",
      "⠨",
      "⠩",
      "⠪",
      "⠫",
      "⠬",
      "⠭",
      "⠮",
      "⠯",
      "⡨",
      "⡩",
      "⡪",
      "⡫",
      "⡬",
      "⡭",
      "⡮",
      "⡯",
      "⠰",
      "⠱",
      "⠲",
      "⠳",
      "⠴",
      "⠵",
      "⠶",
      "⠷",
      "⡰",
      "⡱",
      "⡲",
      "⡳",
      "⡴",
      "⡵",
      "⡶",
      "⡷",
      "⠸",
      "⠹",
      "⠺",
      "⠻",
      "⠼",
      "⠽",
      "⠾",
      "⠿",
      "⡸",
      "⡹",
      "⡺",
      "⡻",
      "⡼",
      "⡽",
      "⡾",
      "⡿",
      "⢀",
      "⢁",
      "⢂",
      "⢃",
      "⢄",
      "⢅",
      "⢆",
      "⢇",
      "⣀",
      "⣁",
      "⣂",
      "⣃",
      "⣄",
      "⣅",
      "⣆",
      "⣇",
      "⢈",
      "⢉",
      "⢊",
      "⢋",
      "⢌",
      "⢍",
      "⢎",
      "⢏",
      "⣈",
      "⣉",
      "⣊",
      "⣋",
      "⣌",
      "⣍",
      "⣎",
      "⣏",
      "⢐",
      "⢑",
      "⢒",
      "⢓",
      "⢔",
      "⢕",
      "⢖",
      "⢗",
      "⣐",
      "⣑",
      "⣒",
      "⣓",
      "⣔",
      "⣕",
      "⣖",
      "⣗",
      "⢘",
      "⢙",
      "⢚",
      "⢛",
      "⢜",
      "⢝",
      "⢞",
      "⢟",
      "⣘",
      "⣙",
      "⣚",
      "⣛",
      "⣜",
      "⣝",
      "⣞",
      "⣟",
      "⢠",
      "⢡",
      "⢢",
      "⢣",
      "⢤",
      "⢥",
      "⢦",
      "⢧",
      "⣠",
      "⣡",
      "⣢",
      "⣣",
      "⣤",
      "⣥",
      "⣦",
      "⣧",
      "⢨",
      "⢩",
      "⢪",
      "⢫",
      "⢬",
      "⢭",
      "⢮",
      "⢯",
      "⣨",
      "⣩",
      "⣪",
      "⣫",
      "⣬",
      "⣭",
      "⣮",
      "⣯",
      "⢰",
      "⢱",
      "⢲",
      "⢳",
      "⢴",
      "⢵",
      "⢶",
      "⢷",
      "⣰",
      "⣱",
      "⣲",
      "⣳",
      "⣴",
      "⣵",
      "⣶",
      "⣷",
      "⢸",
      "⢹",
      "⢺",
      "⢻",
      "⢼",
      "⢽",
      "⢾",
      "⢿",
      "⣸",
      "⣹",
      "⣺",
      "⣻",
      "⣼",
      "⣽",
      "⣾",
      "⣿",
    ]
  )

  skLine* = Spinner(interval: 130, frames: @[
      "-",
      "\\",
      "|",
      "/",
    ]
  )

  skLine2* = Spinner(interval: 100, frames: @[
      "⠂",
      "-",
      "–",
      "—",
      "–",
      "-",
    ]
  )

  skPipe* = Spinner(interval: 100, frames: @[
      "┤",
      "┘",
      "┴",
      "└",
      "├",
      "┌",
      "┬",
      "┐",
    ]
  )

  skSimpleDots* = Spinner(interval: 400, frames: @[
      ".  ",
      ".. ",
      "...",
      "   ",
    ]
  )

  skSimpleDotsScrolling* = Spinner(interval: 200, frames: @[
      ".  ",
      ".. ",
      "...",
      " ..",
      "  .",
      "   ",
    ]
  )

  skStar* = Spinner(interval: 70, frames: @[
      "✶",
      "✸",
      "✹",
      "✺",
      "✹",
      "✷",
    ]
  )

  skStar2* = Spinner(interval: 80, frames: @[
      "+",
      "x",
      "*",
    ]
  )

  skFlip* = Spinner(interval: 70, frames: @[
      "_",
      "_",
      "_",
      "-",
      "`",
      "`",
      "'",
      "´",
      "-",
      "_",
      "_",
      "_",
    ]
  )

  skHamburger* = Spinner(interval: 100, frames: @[
      "☱",
      "☲",
      "☴",
    ]
  )

  skGrowVertical* = Spinner(interval: 120, frames: @[
      "▁",
      "▃",
      "▄",
      "▅",
      "▆",
      "▇",
      "▆",
      "▅",
      "▄",
      "▃",
    ]
  )

  skGrowHorizontal* = Spinner(interval: 120, frames: @[
      "▏",
      "▎",
      "▍",
      "▌",
      "▋",
      "▊",
      "▉",
      "▊",
      "▋",
      "▌",
      "▍",
      "▎",
    ]
  )

  skBalloon* = Spinner(interval: 140, frames: @[
      " ",
      ".",
      "o",
      "O",
      "@",
      "*",
      " ",
    ]
  )

  skBalloon2* = Spinner(interval: 120, frames: @[
      ".",
      "o",
      "O",
      "°",
      "O",
      "o",
      ".",
    ]
  )

  skNoise* = Spinner(interval: 100, frames: @[
      "▓",
      "▒",
      "░",
    ]
  )

  skBounce* = Spinner(interval: 120, frames: @[
      "⠁",
      "⠂",
      "⠄",
      "⠂",
    ]
  )

  skBoxBounce* = Spinner(interval: 120, frames: @[
      "▖",
      "▘",
      "▝",
      "▗",
    ]
  )

  skBoxBounce2* = Spinner(interval: 100, frames: @[
      "▌",
      "▀",
      "▐",
      "▄",
    ]
  )

  skTriangle* = Spinner(interval: 50, frames: @[
      "◢",
      "◣",
      "◤",
      "◥",
    ]
  )

  skArc* = Spinner(interval: 100, frames: @[
      "◜",
      "◠",
      "◝",
      "◞",
      "◡",
      "◟",
    ]
  )

  skCircle* = Spinner(interval: 120, frames: @[
      "◡",
      "⊙",
      "◠",
    ]
  )

  skSquareCorners* = Spinner(interval: 180, frames: @[
      "◰",
      "◳",
      "◲",
      "◱",
    ]
  )

  skCircleQuarters* = Spinner(interval: 120, frames: @[
      "◴",
      "◷",
      "◶",
      "◵",
    ]
  )

  skCircleHalves* = Spinner(interval: 50, frames: @[
      "◐",
      "◓",
      "◑",
      "◒",
    ]
  )

  skSquish* = Spinner(interval: 100, frames: @[
      "╫",
      "╪",
    ]
  )

  skToggle* = Spinner(interval: 250, frames: @[
      "⊶",
      "⊷",
    ]
  )

  skToggle2* = Spinner(interval: 80, frames: @[
      "▫",
      "▪",
    ]
  )

  skToggle3* = Spinner(interval: 120, frames: @[
      "□",
      "■",
    ]
  )

  skToggle4* = Spinner(interval: 100, frames: @[
      "■",
      "□",
      "▪",
      "▫",
    ]
  )

  skToggle5* = Spinner(interval: 100, frames: @[
      "▮",
      "▯",
    ]
  )

  skToggle6* = Spinner(interval: 300, frames: @[
      "ဝ",
      "၀",
    ]
  )

  skToggle7* = Spinner(interval: 80, frames: @[
      "⦾",
      "⦿",
    ]
  )

  skToggle8* = Spinner(interval: 100, frames: @[
      "◍",
      "◌",
    ]
  )

  skToggle9* = Spinner(interval: 100, frames: @[
      "◉",
      "◎",
    ]
  )

  skToggle10* = Spinner(interval: 100, frames: @[
      "㊂",
      "㊀",
      "㊁",
    ]
  )

  skToggle11* = Spinner(interval: 50, frames: @[
      "⧇",
      "⧆",
    ]
  )

  skToggle12* = Spinner(interval: 120, frames: @[
      "☗",
      "☖",
    ]
  )

  skToggle13* = Spinner(interval: 80, frames: @[
      "=",
      "*",
      "-",
    ]
  )

  skArrow* = Spinner(interval: 100, frames: @[
      "←",
      "↖",
      "↑",
      "↗",
      "→",
      "↘",
      "↓",
      "↙",
    ]
  )

  skArrow2* = Spinner(interval: 80, frames: @[
      "⬆️ ",
      "↗️ ",
      "➡️ ",
      "↘️ ",
      "⬇️ ",
      "↙️ ",
      "⬅️ ",
      "↖️ ",
    ]
  )

  skArrow3* = Spinner(interval: 120, frames: @[
      "▹▹▹▹▹",
      "▸▹▹▹▹",
      "▹▸▹▹▹",
      "▹▹▸▹▹",
      "▹▹▹▸▹",
      "▹▹▹▹▸",
    ]
  )

  skBouncingBar* = Spinner(interval: 80, frames: @[
      "[    ]",
      "[=   ]",
      "[==  ]",
      "[=== ]",
      "[ ===]",
      "[  ==]",
      "[   =]",
      "[    ]",
      "[   =]",
      "[  ==]",
      "[ ===]",
      "[====]",
      "[=== ]",
      "[==  ]",
      "[=   ]",
    ]
  )

  skBouncingBall* = Spinner(interval: 80, frames: @[
      "( ●    )",
      "(  ●   )",
      "(   ●  )",
      "(    ● )",
      "(     ●)",
      "(    ● )",
      "(   ●  )",
      "(  ●   )",
      "( ●    )",
      "(●     )",
    ]
  )

  skSmiley* = Spinner(interval: 200, frames: @[
      "😄 ",
      "😝 ",
    ]
  )

  skMonkey* = Spinner(interval: 300, frames: @[
      "🙈 ",
      "🙈 ",
      "🙉 ",
      "🙊 ",
    ]
  )

  skHearts* = Spinner(interval: 100, frames: @[
      "💛 ",
      "💙 ",
      "💜 ",
      "💚 ",
      "❤️ ",
    ]
  )

  skClock* = Spinner(interval: 100, frames: @[
      "🕛 ",
      "🕐 ",
      "🕑 ",
      "🕒 ",
      "🕓 ",
      "🕔 ",
      "🕕 ",
      "🕖 ",
      "🕗 ",
      "🕘 ",
      "🕙 ",
      "🕚 ",
    ]
  )

  skEarth* = Spinner(interval: 180, frames: @[
      "🌍 ",
      "🌎 ",
      "🌏 ",
    ]
  )

  skMoon* = Spinner(interval: 80, frames: @[
      "🌑 ",
      "🌒 ",
      "🌓 ",
      "🌔 ",
      "🌕 ",
      "🌖 ",
      "🌗 ",
      "🌘 ",
    ]
  )

  skRunner* = Spinner(interval: 140, frames: @[
      "🚶 ",
      "🏃 ",
    ]
  )

  skPong* = Spinner(interval: 80, frames: @[
      "▐⠂       ▌",
      "▐⠈       ▌",
      "▐ ⠂      ▌",
      "▐ ⠠      ▌",
      "▐  ⡀     ▌",
      "▐  ⠠     ▌",
      "▐   ⠂    ▌",
      "▐   ⠈    ▌",
      "▐    ⠂   ▌",
      "▐    ⠠   ▌",
      "▐     ⡀  ▌",
      "▐     ⠠  ▌",
      "▐      ⠂ ▌",
      "▐      ⠈ ▌",
      "▐       ⠂▌",
      "▐       ⠠▌",
      "▐       ⡀▌",
      "▐      ⠠ ▌",
      "▐      ⠂ ▌",
      "▐     ⠈  ▌",
      "▐     ⠂  ▌",
      "▐    ⠠   ▌",
      "▐    ⡀   ▌",
      "▐   ⠠    ▌",
      "▐   ⠂    ▌",
      "▐  ⠈     ▌",
      "▐  ⠂     ▌",
      "▐ ⠠      ▌",
      "▐ ⡀      ▌",
      "▐⠠       ▌",
    ]
  )

  skShark* = Spinner(interval: 120, frames: @[
      "▐|\\____________▌",
      "▐_|\\___________▌",
      "▐__|\\__________▌",
      "▐___|\\_________▌",
      "▐____|\\________▌",
      "▐_____|\\_______▌",
      "▐______|\\______▌",
      "▐_______|\\_____▌",
      "▐________|\\____▌",
      "▐_________|\\___▌",
      "▐__________|\\__▌",
      "▐___________|\\_▌",
      "▐____________|\\▌",
      "▐____________/|▌",
      "▐___________/|_▌",
      "▐__________/|__▌",
      "▐_________/|___▌",
      "▐________/|____▌",
      "▐_______/|_____▌",
      "▐______/|______▌",
      "▐_____/|_______▌",
      "▐____/|________▌",
      "▐___/|_________▌",
      "▐__/|__________▌",
      "▐_/|___________▌",
      "▐/|____________▌",
    ]
  )

  skDqpb* = Spinner(interval: 100, frames: @[
      "d",
      "q",
      "p",
      "b",
    ]
  )

  skWeather* = Spinner(interval: 100, frames: @[
      "☀️ ",
      "☀️ ",
      "☀️ ",
      "🌤 ",
      "⛅️ ",
      "🌥 ",
      "☁️ ",
      "🌧 ",
      "🌨 ",
      "🌧 ",
      "🌨 ",
      "🌧 ",
      "🌨 ",
      "⛈ ",
      "🌨 ",
      "🌧 ",
      "🌨 ",
      "☁️ ",
      "🌥 ",
      "⛅️ ",
      "🌤 ",
      "☀️ ",
      "☀️ ",
    ]
  )

  skChristmas* = Spinner(interval: 400, frames: @[
      "🌲",
      "🎄",
    ]
  )

  skGrenade* = Spinner(interval: 80, frames: @[
      "،   ",
      "′   ",
      " ´ ",
      " ‾ ",
      "  ⸌",
      "  ⸊",
      "  |",
      "  ⁎",
      "  ⁕",
      " ෴ ",
      "  ⁓",
      "   ",
      "   ",
      "   ",
    ]
  )

  skPoint* = Spinner(interval: 125, frames: @[
      "∙∙∙",
      "●∙∙",
      "∙●∙",
      "∙∙●",
      "∙∙∙",
    ]
  )

  skLayer* = Spinner(interval: 150, frames: @[
      "-",
      "=",
      "≡",
    ]
  )

  skBetaWave* = Spinner(interval: 80, frames: @[
      "ρββββββ",
      "βρβββββ",
      "ββρββββ",
      "βββρβββ",
      "ββββρββ",
      "βββββρβ",
      "ββββββρ",
    ]
  )