# statuscache.nim

import
  json, os, asyncdispatch,
  ../utils/utils, strutils,
  times, terminal,

  ../ui/stationstatus

#[spec
    {
        "lastChecked": "<stdanrd-datetime-format>",
        "stationlist": {
            "<name>": 0|1,
            ...
        }
    }
]#

using
  stations: seq[StationStatus]
  statuscontext: StatusCache

proc getCacheJsonFileNameWithPath(sectionName: var string) =
  sectionName[0] = sectionName[0].toLowerAscii()
  sectionName = sectionName & ".cache.json"
  sectionName = appDir / ".statuscache" / sectionName
    #Arab -> arab -> arab.cache.json -> path/to/<>

proc removeOldCacheForJson(statuscontext) =
  var filePathNameExt = statuscontext.sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)

  try:
    removeFile(filePathNameExt)
  except:
    warn "cant remove cacheFile"

proc checkIfCacheAlreadyExistAndIsValid*(stations; statuscontext): bool =
  var filePathNameExt = statuscontext.sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)

  let exists = fileExists(filePathNameExt)
  let absPath = absolutePath(filePathNameExt)
  let absExists = fileExists(absPath)

  if not (exists and absExists):
    return false

  try:
    let jsonParsedCacheObj = parseFile(filePathNameExt)
    let cacheLastTimeStr = jsonParsedCacheObj["lastCheckedDateTime"].getStr()
    let cacheTime = parse(cacheLastTimeStr, "yyyy-MM-dd'T'HH:mm:sszzz")
    let currentTime = now()
    let timeDiff = currentTime - cacheTime
    return timeDiff.inSeconds <= 24 * 3600  # 24 hours in seconds
  except:
    # Handle any parsing errors (invalid JSON, missing key, etc.)
    return false

template cE(status: bool) =
  if not status:
    raise newException(OSError, "An OS error occurred")

proc linkStatustoBool(status: LinkStatus): uint8 =
  case status
  of lsInvalid: 0 #false
  of lsValid:   1 #true
  of lsChecking:
    raise newException(OSError, "are you writing CheckingStatus to cache?")

proc boolToLinkStatus(status: int): LinkStatus =
  case status
  of 0: lsInvalid  #false
  of 1: lsValid    #true
  else:
    raise newException(OSError, "are you writing CheckingStatus to cache?")

proc saveStatusCacheToJson(stations; statuscontext) =
  var fileInConsideration: File
  var jsonObjectCache = %*{}
  var filePathNameExt = statuscontext.sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)
  
  cE open(fileInConsideration, filePathNameExt, fmWrite)

  jsonObjectCache["lastCheckedDateTime"] = %* $now()


  var stationList = newJObject()
  # Populate the stationlist

  for station in stations:
    # The key is the station name, the value is a 0 or 1 boolean
    stationList[station.name] = % linkStatustoBool(station.status)

  # Add the stationlist to the main object
  jsonObjectCache["stationlist"] = stationList

  var uglyResultJson: string
  uglyResultJson.toUgly(jsonObjectCache)

  fileInConsideration.write(uglyResultJson)
  fileInConsideration.close()

proc readFromExistingStatusCache*(stations; statuscontext): JsonNode =
  var filePathNameExt = statuscontext.sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)

  var parsedCachedJson = parseFile(filePathNameExt)
  return parsedCachedJson["stationlist"]

type CacheDoesntMatchParentJsonError = object of CatchableError

template waitForResolveNewStatusAndSave =
  initCheckingStationNotice()
  waitFor resolveAndDisplay(stations)
  finishCheckingStationNotice()
  saveStatusCacheToJson(stations, statuscontext)

proc handleApplytoCacheError(e: ref Exception; stations; statuscontext): bool =
  if e of IndexDefect:
    warn "the cache list is larger than json file; please restart if crash"
  elif e of CacheDoesntMatchParentJsonError:
    warn "the cache json is not matching; please restart if crash"

  sleep 750
  cursorUp()
  eraseLine()

  removeOldCacheForJson(statuscontext)
  return false

proc applyLinkStatusFromCacheToState(stations; stationsList: JsonNode; statuscontext): bool =
  var i: uint8
  try:
    for key, value in  stationsList.pairs:
      if key != stations[i].name:
        raise newException(CacheDoesntMatchParentJsonError, "")
      stations[i].status = boolToLinkStatus value.getInt
      drawStatusIndicator(stations[i].coord[0], stations[i].coord[1], stations[i].status)
      i += 1
    return true
  except Exception as e:
    return e.handleApplytoCacheError(stations, statuscontext)

proc hookCacheResolveAndDisplay*(stations; statuscontext) =
  when defined(statuscache):
    if not checkIfCacheAlreadyExistAndIsValid(stations, statuscontext):
      waitForResolveNewStatusAndSave()
    else:
      let cacheStatusStationList = readFromExistingStatusCache(stations, statuscontext)
      if not stations.applyLinkStatusFromCacheToState(cacheStatusStationList, statuscontext):
        waitForResolveNewStatusAndSave()
  else:
    waitFor resolveAndDisplay(stations)
