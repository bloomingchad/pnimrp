# stationstatus.nim
import terminal, utils

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