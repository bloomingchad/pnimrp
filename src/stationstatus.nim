# stationstatus.nim
import terminal, utils

proc drawStatusIndicator*(x, y: int, status: LinkStatus) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  styledEcho(fgYellow, "🟡")
  hideCursor()