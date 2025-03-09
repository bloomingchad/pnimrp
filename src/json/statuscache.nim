# statuscache.nim

import
  json, os, asyncdispatch, ../utils/utils, strutils, times, sequtils,

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

#proc addToJsonAndReturn()

proc getCacheJsonFileNameWithPath(sectionName: var string) =
  sectionName[0] = sectionName[0].toLowerAscii()
  sectionName = sectionName & ".cache.json"
  sectionName = appDir / ".statuscache" / sectionName
    #Arab -> arab -> arab.cache.json -> path/to/<>

proc checkIfCacheAlreadyExistAndIsValid*(stations): bool =
  var filePathNameExt = stations[0].sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)

  if not fileExists filePathNameExt: return

  let jsonParsedCacheObj = parseFile(filePathNameExt)

  let cacheLastTime = $jsonParsedCacheObj["lastCheckedDateTime"]
  let nowTime = $(now() - initDuration(hours = 24))

  if cacheLastTime > nowTime:
    return true

  return

template cE(status: bool) =
  if not status:
    raise newException(OSError, "An OS error occurred")

proc linkStatustoBool(status: LinkStatus): uint8 =
  case status
  of lsInvalid: 0 #false
  of lsValid:   1 #true
  of lsChecking:
    raise newException(OSError, "are you writing CheckingStatus to cache?")

proc saveStatusCacheToJson(stations) =
  var fileInConsideration: File
  var jsonObjectCache = %*{}
  var filePathNameExt = stations[0].sectionName
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

proc readFromExistingStatusCache*(stations) =
  var fileInConsideration: File
  var filePathNameExt = stations[0].sectionName
  getCacheJsonFileNameWithPath(filePathNameExt)

  var parsedCachedJson = parseFile(filePathNameExt)
  var cachedJsonList = parsedCachedJson["stationlist"]

proc hookCacheResolveAndDisplay*(stations) =
  when defined(expstatuscache):
    if not checkIfCacheAlreadyExistAndIsValid(stations):
      waitFor resolveAndDisplay(stations)
      saveStatusCacheToJson(stations)
    else:
      readFromExistingStatusCache(stations)
  else:
    waitFor resolveAndDisplay(stations)
