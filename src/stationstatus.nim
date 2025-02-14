# stationstatus.nim
import terminal

type
  LinkStatus* = enum
    lsChecking, lsValid, lsInvalid # Only the link states

proc drawStatusIndicator*(x, y: int, status: LinkStatus) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  styledEcho(fgYellow, "🟡")
  hideCursor()