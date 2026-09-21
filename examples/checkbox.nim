import kapsis/interactive/widgets

let picks = promptCheckbox(
  "Select recipes (Space to toggle, Enter to confirm):",
  ["JOSE — JWT via nimbase/jose",
   "Nimcypher — encryption via nimbas/nimcypher",
   "Brotli — compression via nimbase/nbrotli",
   "mimedb — MIME types via openpeeps/mimedb",
   "bag — input validation via openpeeps/bag",
   "blackpaper — password strength via openpeeps/blackpaper",
   "multipart — file uploads via openpeeps/multipart"]
)
echo "picked: ", picks
