import ../src/yacli/runtime

proc runCommand*(v: Values) =
  echo "Hello " & v.get("input")
  if v.flag("jazz"):
    echo "warm nostalgic jazz"