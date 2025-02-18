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
  setCursorPos(x, y)
  let statusEmoji = toStatusCodeEmoji(status)
  stdout.write(statusEmoji)

type
  StationStatus* = ref object     # Changed to ref object for safe capture
    coord*: (int, int)            # (x, y) from emojiPositions
    url*: string
    status*: LinkStatus           # lsChecking/lsValid/lsInvalid
    future*: Future[LinkStatus]

proc checkAndDraw(station: StationStatus) {.async.} =
  station.future = resolveLink(station.url)  # Store future
  station.status = await station.future      # Wait only THIS station's check
  drawStatusIndicator(station.coord[0], station.coord[1], station.status)
  stdout.flushFile()
    #flush to actually send the written stdout to stdout
    #this gives us immediate status display effect

proc resolveAndDisplay*(stations: seq[StationStatus]) {.async.} =
  ## Asynchronously resolves and displays status for each station independently.
  ## Each station's status will update as soon as its check completes.
  var allChecks: seq[Future[void]] = @[]
  
  for station in stations:
    allChecks.add(checkAndDraw(station))
    
  await all(allChecks)  # Wait for all checks to complete before returning
