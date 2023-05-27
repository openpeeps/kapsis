import ../src/kapsis/runtime

proc runCommand*(v: Values) =
  echo "Running new command with " & v.get("app") & " option"