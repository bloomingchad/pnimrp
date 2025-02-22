# stationstatus.nim

import terminal, utils, asynclink, asyncdispatch

proc initCheckingStationNotice* =
  setCursorPos(2, lastMenuSeparatorY + 4)
  stdout.write "Checking stations... Please Wait"
  flushFile stdout

proc finishCheckingStationNotice* = 
  setCursorPos 2, lastMenuSeparatorY + 4
  eraseLine()
  lastMenuSeparatorY = 0

proc toStatusCodeEmoji(status: LinkStatus): string =
  case status
  of lsValid:    "🟢"
  of lsInvalid:  "🔴"
  of lsChecking: "🟡"

# Combine similar status indicator functions
proc drawStatusIndicator*(x, y: int, status = lsChecking, isInitial = false) =
  setCursorPos(x, y)
  let statusEmoji = if isInitial: "🟡" else: toStatusCodeEmoji(status)
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

proc drawMenuEmojis* =
  ## Draws the menu emojis at the stored positions.
  for pos in emojiPositions:
    drawStatusIndicator(pos[0], pos[1], lsChecking) # Use lsChecking

proc initDrawMenuEmojis* =
  ## Draws the yellow menu emojis at the stored positions.
  for pos in emojiPositions:
    drawStatusIndicator(pos[0], pos[1], isInitial = true)
