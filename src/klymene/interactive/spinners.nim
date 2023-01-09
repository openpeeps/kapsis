from std/os import sleep
export sleep

# https://github.com/sindresorhus/cli-spinners/blob/main/spinners.json

type 
    TSpinner* = enum
        Basic
        Bold
        BlockUp
        WalkingDots
        ElasticBall
        Aesthetic
        AestheticArrows
        Pointless

    Spinner = object
        tSpinner: TSpinner
        chars: seq[string]
        offset: int
        length: int

proc initSpinner(tSpinner: TSpinner, chars: seq[string]): ref Spinner =
    new result
    result.tSpinner = Basic
    result.chars = chars
    result.length = chars.len

proc newSpinner*(tSpinner: TSpinner = Basic): ref Spinner =
    var chars: seq[string]
    case tSpinner:
    of Basic:
        chars = @["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    of Bold:
        chars = @["▛","▜","▟","▙"]
    of BlockUp:
        chars = @["▁", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃"]
    of WalkingDots:
        chars = @["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"]
    of ElasticBall:
        chars = @[
            "| ●    |",
            "|  ●   |",
            "|   ●  |",
            "|    ● |",
            "|     ●)",
            "|    ● |",
            "|   ●  |",
            "|  ●   |",
            "| ●    |",
            "(●     |"
        ]
    of Aesthetic:
        chars = @[
            "▰▱▱▱▱▱▱",
            "▰▰▱▱▱▱▱",
            "▰▰▰▱▱▱▱",
            "▰▰▰▰▱▱▱",
            "▰▰▰▰▰▱▱",
            "▰▰▰▰▰▰▱",
            "▰▰▰▰▰▰▰",
            "▰▱▱▱▱▱▱"
        ]
    of AestheticArrows:
        chars = @[
            "▹▹▹▹▹",
            "▸▹▹▹▹",
            "▹▸▹▹▹",
            "▹▹▸▹▹",
            "▹▹▹▸▹",
            "▹▹▹▹▸"
        ]
    of Pointless:
        chars = @[
            "∙∙∙",
            "●∙∙",
            "∙●∙",
            "∙∙●",
            "∙∙∙"
        ]
    result = initSpinner(tSpinner, chars)

proc update*(s: ref Spinner): string =
    if s.offset > (s.length - 1):
        s.offset = 0
    result = $(s.chars[s.offset])
    inc s.offset