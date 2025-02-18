import terminal, utils, linkresolver, asyncdispatch, os

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
  StationStatus* = ref object     # Changed to ref object for safe capture
    coord*: (int, int)            # (x, y) from emojiPositions
    url*: string
    status*: LinkStatus           # lsChecking/lsValid/lsInvalid

proc resolveAndDisplay*(stations: seq[StationStatus]) {.async.} =
  ## Processes stations asynchronously:
  ## 1. Launches all link checks async
  ## 2. Waits till all end
  ## 3. Draws emoji for each station
  var futures = newSeq[Future[LinkStatus]](stations.len)

  # Launch all link checks async
  for i in 0..<stations.len:
    futures[i] = resolveLink(stations[i].url)

  # Wait for all futures to complete
  let results = await all(futures)

  # Update statuses and draw emojis
  for i in 0..<stations.len:
    stations[i].status = results[i]  # Using results directly
    drawStatusIndicator(
      stations[i].coord[0],  # x
      stations[i].coord[1],  # y
      stations[i].status
    )
