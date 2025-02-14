# stationstatus.nim
import terminal

proc drawStatusIndicator*(x, y: int) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  styledEcho(fgYellow, "🟡")
  hideCursor()