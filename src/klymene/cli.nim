from std/strutils import `%`, spaces, indent

const BR = ""

proc display*(label: string, color: string = "white", indent=0, br="") =
    ## Display a single line in one color
    var text: string
    if indent == 0: text = label
    else: text = label.indent(indent)

    if br == "before" or br == "both": echo BR  # add a new line before label
    # if color.len == 0:
    # else:
    cli_colors.white(text)
    if br == "after" or br == "both": echo BR   # add a new line after label

proc displayInfo*() = 
    ## Display ``info`` label with a predefined icon and color

proc displaySuccess*() = 
    ## Display ``success`` label with a predefined icon and color

proc displayWarning*() =
    ## Display ``warning`` label with a predefined icon and color

proc displayError*() =
    ## Display ``error` label with a predefined icon and color

proc prompt*(label: string, color: string = "white", default=""): string =
    ## Prompt a question line and retrieve the input
    display(label)
    var answer = stdin.readLine()
    if default.len != 0 and answer.len == 0:
       return default
    return answer

proc promptSecret*(label: string, color:string="white", required=true): string =
    ## Prompt a hidden field and read from secret input
    display(label)
    let inputPassword = terminal.readPasswordFromStdin()
    if inputPassword.len == 0 and required == true:
        return promptSecret(label, required=true)
    return inputPassword

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
    else: promptConfirm(label)