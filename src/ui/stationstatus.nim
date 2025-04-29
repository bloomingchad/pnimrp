# SPDX-License-Identifier: MPL-2.0
# stationstatus.nim

import terminal, asyncdispatch,
  ../utils/utils,
  ../link/asynclink

func toStatusCodeEmoji(status: LinkStatus): (ForegroundColor, string) =
  when not defined(noEmoji):
    case status
    of lsValid:    (fgDefault, "🟢")
    of lsInvalid:  (fgDefault, "🔴")
    of lsChecking: (fgDefault, "🟡")
  else:
    case status
    of lsValid:    (fgGreen,  "/")
    of lsInvalid:  (fgRed,    "x")
    of lsChecking: (fgYellow, "o")

proc drawStatusIndicator*(x, y: int, status = lsChecking, isInitial = false) =
  setCursorPos(x, y)
  let (color, symbol) =
    if isInitial:
        when not defined(noEmoji): (fgDefault, "🟡")
        else: (fgYellow, "o")
    else:
      toStatusCodeEmoji(status)
  stdout.styledWrite(color, symbol)
  stdout.flushFile()

type
  StationStatus* = ref object
    name*:     string
    coord*:    (int, int)
    url*:      string
    status*:   LinkStatus
    future*:   Future[LinkStatus]

proc checkAndDraw(station: StationStatus) {.async.} =
  station.future = resolveLink(station.url) # Store future
  await sleepAsync(5)
  station.status = await station.future
  await sleepAsync(5)
  drawStatusIndicator(station.coord[0], station.coord[1], station.status)
  stdout.flushFile()
    #flush to actually send the written stdout to stdout
    #this gives us immediate status display effect

proc resolveAndDisplay*(stations: seq[StationStatus]) {.async.} =
  var allChecks = newSeqOfCap[Future[void]](32)

  for station in stations:
    allChecks.add(checkAndDraw(station))

  await all(allChecks)

proc drawMenuEmojis* =
  for pos in emojiPositions:
    drawStatusIndicator(pos[0], pos[1], lsChecking)

proc initDrawMenuEmojis* =
  for pos in emojiPositions:
    drawStatusIndicator(pos[0], pos[1], isInitial = true)
