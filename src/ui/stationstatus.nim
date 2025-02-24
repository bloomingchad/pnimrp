# stationstatus.nim

import terminal, asyncdispatch,
  ../utils/utils,
  ../link/asynclink

proc initCheckingStationNotice* =
  setCursorPos(2, lastMenuSeparatorY + 4)
  stdout.write "Checking stations... Please Wait"
  flushFile stdout

proc finishCheckingStationNotice* = 
  setCursorPos 2, lastMenuSeparatorY + 4
  eraseLine()
  lastMenuSeparatorY = 0

proc toStatusCodeEmoji(status: LinkStatus): (ForegroundColor, string) =
  when not defined(noEmoji):
    case status
    of lsValid:    (fgDefault, "🟢")
    of lsInvalid:  (fgDefault, "🔴")
    of lsChecking: (fgDefault, "🟡")
  else:
    case status
    of lsValid:    (fgGreen,  "√")  # Green checkmark
    of lsInvalid:  (fgRed,    "x")  # Red cross
    of lsChecking: (fgYellow, "o")  # Yellow circle (Unicode U+25CC)

# Combine similar status indicator functions
proc drawStatusIndicator*(x, y: int, status = lsChecking, isInitial = false) =
  setCursorPos(x, y)
  let (color, symbol) = 
    if isInitial:
        when not defined(noEmoji): (fgDefault, "🟡")
        else: (fgYellow, "o")  # Yellow circle for initial state
    else:
      toStatusCodeEmoji(status)
  # Apply color and write symbol
  stdout.setForegroundColor(color)
  stdout.write(symbol)
  stdout.resetAttributes()
  stdout.flushFile()

type
  StationStatus* = ref object
    coord*: (int, int)            # (x, y) from emojiPositions
    url*: string
    status*: LinkStatus
    future*: Future[LinkStatus]

proc checkAndDraw(station: StationStatus) {.async.} =
  station.future = resolveLink(station.url)  # Store future
  station.status = await station.future
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
    drawStatusIndicator(pos[0], pos[1], lsChecking)

proc initDrawMenuEmojis* =
  ## Draws the yellow menu emojis at the stored positions.
  for pos in emojiPositions:
    drawStatusIndicator(pos[0], pos[1], isInitial = true)
