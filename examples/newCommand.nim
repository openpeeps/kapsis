import ../src/klymene/runtime

proc runCommand*(v: Values) =
  echo "Running new command with " & v.get("app") & " option"