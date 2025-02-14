# stationstatus.nim
import terminal, utils

proc initStatusIndicator*(x, y: int) =
  ## Initializes the status indicator to the "checking" state (yellow circle).
  setCursorPos(x, y)
  styledEcho(fgYellow, "🟡")
  hideCursor()

proc drawStatusIndicator*(x, y: int, status: LinkStatus) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  case status
  of lsChecking:
    styledEcho(fgYellow, "🟡")
  of lsValid:
    styledEcho(fgGreen, "🟢")
  of lsInvalid:
    styledEcho(fgRed, "🔴")