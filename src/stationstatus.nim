# stationstatus.nim
import terminal, utils, linkresolver

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
  ## Draws without moving global cursor
  let prevPos = getCursorPos()
  setCursorPos(x, y)
  let statusEmoji = toStatusCodeEmoji(status)
  stdout.write(statusEmoji)
  setCursorPos(prevPos.x, prevPos.y)  # Restore original position

type
  StationStatus* = object
    coord*: (int, int)    # (x, y) from emojiPositions
    url*: string
    status*: LinkStatus    # lsChecking/lsValid/lsInvalid

proc resolveAndDisplay*(stations: var seq[StationStatus]) =
  ## Processes stations sequentially:
  ## 1. Resolves URL
  ## 2. Updates status
  ## 3. Draws emoji
  for i in 0..<stations.len:
    # Resolve link (blocking call)
    stations[i].status = resolveLinkSync(stations[i].url)
    
    # Update UI
    drawStatusIndicator(
      stations[i].coord[0],  # x
      stations[i].coord[1],  # y
      stations[i].status
    )
