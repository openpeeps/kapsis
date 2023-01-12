template getCallbackIdent(): untyped =
  # Retrieve a callback identifier name based on command id
  var commandCallbackIdent: string
  parentCommands.add(subCommandId)
  if isSubCommand:
    for k, pCommand in pairs(parentCommands):
      var word: string
      for kk, charCommand in pairs(pCommand):
        if k == 0 and kk == 0:
          word &= charCommand
        elif kk == 0:
          word &= toUpperAscii(charCommand)
        else: word &= charCommand
      commandCallbackIdent &= word
    commandCallbackIdent &= "Command"
  else:
    commandCallbackIdent = newCommandId.strVal & "Command"
  commandCallbackIdent