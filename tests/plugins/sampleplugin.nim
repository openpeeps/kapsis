import pkg/pluginkit
import pkg/kapsis/pluginapi

plugin sampleplugin, {
  name: "SamplePlugin",
  author: "George Lemon",
  description: "A Kapsis plugin that contributes CLI commands",
  license: "MIT",
  version: "1.0.0"
}:
  commands do:
    greet name.string, ?string(greeting):
      ## Greet someone
      echo "HELLO " & v.get("name").getStr
      if v.has("greeting"):
        echo "MSG  " & v.get("greeting").getStr

    colors:
      ## Explore colors
      blue bool(enable):
        echo "blue = ", v.get("enable").getBool