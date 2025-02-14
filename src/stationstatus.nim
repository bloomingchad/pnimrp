# stationstatus.nim
import terminal, utils

proc initStatusIndicator*(x, y: int) =
  ## Initializes the status indicator to the "checking" state (yellow circle).
  setCursorPos(x, y)
  stdout.write("🟡")
  hideCursor()

proc drawStatusIndicator*(x, y: int, status: LinkStatus) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  case status
  of lsChecking:
    stdout.write("🟡")
  of lsValid:
    stdout.write("🟢")
  of lsInvalid:
    stdout.write("🔴")