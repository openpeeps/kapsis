import pkg/kapsis
import pkg/kapsis/runtime

proc helloCommand(v: Values) =
  echo "hello ", v.get("name").getStr

initKapsis do:
  plugins do:
    dir: "plugins"
  commands do:
    hello name.string:
      ## A built-in command