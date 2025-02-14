# stationstatus.nim
import terminal, utils

proc initStatusIndicator*(x, y: int) =
  ## Initializes the status indicator to the "checking" state (yellow circle).
  setCursorPos(x, y)
  stdout.write("🟡")

proc toStatusCodeEmoji(status: LinkStatus): string =
  case status
  of lsValid:    "🟢"
  of lsInvalid:  "🔴"
  of lsChecking: "🟡"  

proc drawStatusIndicator*(x, y: int, status: LinkStatus) =
  ## Draws the status indicator emoji at the specified position.
  setCursorPos(x, y)
  stdout.write(status.toStatusCodeEmoji())

type
  StationResolverCouple* = object
    coordOfEmoji*: tuple[x, y: int]  # Emoji's terminal coordinates
    statusCode*: LinkStatus          # Current link status (lsChecking, lsValid, lsInvalid)
    url*: string                     # Station URL to resolve
