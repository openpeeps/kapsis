import pkg/pixie

let
  imgWidth = 1560
  imgHeight = 890
  innerWidth = 1400
  innerHeight = 700

let image = newImage(imgWidth, imgHeight)
image.fill(rgba(255, 255, 255, 0))

let ctx = newContext(image)
ctx.fillStyle = rgba(21, 23, 24, 255)

let
  pos = vec2((imgWidth - innerWidth) / 2, (imgHeight - innerHeight) / 2)
  wh = vec2(toFloat(innerWidth), toFloat(innerHeight))
  r = 25.0

ctx.fillRoundedRect(rect(pos, wh), r)


# setup font
let tf = readTypeface("/System/Library/Fonts/Arial.ttf")
proc newFont(tf: Typeface, size: float32, color: Color): Font =
  result = newFont(tf)
  result.size = size
  result.paint.color = color
  result.lineHeight = 39.0

let baseFont = newFont(tf, 24, color(0.78, 0.78, 0.78, 1))
let heading = newFont(tf, 24, color(1.0, 1.0, 1.0, 1))
let comments = newFont(tf, 24, color(0.50, 0.50, 0.50, 1))
let spans = @[
  newSpan("Bro - A super fast stylesheet language for cool kids!\n", comments),
  newSpan("https://github.com/openpeeps/bro\n\n", comments),
  
  newSpan("<style> <output> --min --map --cache", baseFont),
  newSpan("                Compiles a stylesheet to CSS\n", comments),
  
  newSpan("\nDevelopment\n", heading),
  newSpan("watch <style> <output> --min --map", baseFont),
  newSpan("                  Watch for changes and compile\n", comments),
  newSpan("ast <style> <output>", baseFont),
  newSpan("                                Generates binary AST", comments),
]

# ctx.fillText(typeset(spans, vec2(180, 180)), translate(vec2(10, 10)))
# ctx.fillText("blabla", vec2(180, 180))
image.fillText(typeset(spans, vec2(1400, 700)), translate(vec2(140, 140)))
image.writeFile("./rounded_rectangle.png")