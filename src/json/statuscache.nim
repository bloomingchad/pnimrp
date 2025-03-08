# statuscache.nim

import
  json, os, asyncdispatch, ../utils/utils,

  ../ui/stationstatus


#[
    {
        "lastChecked": "<stdanrd-datetime-format>",
        "stationlist": {
            "<name>": "ls<Status>",
            ...
        }
    }
]#


proc checkIfCacheAlreadyExistAndIsValid*(station: seq[StationStatus]): bool = false #dummy

proc saveStatusCacheToJson(JsonFileReprSubMenu: string) =
  checkIfCacheDirExistElseCreate()

  var fileInConsideration: File

  discard open(fileInConsideration, JsonFileReprSubMenu, fmWrite)

proc readFromExistingStatusCache*(stations: seq[StationStatus]) = discard

proc hookCacheResolveAndDisplay*(stations: seq[StationStatus]) =
  if not checkIfCacheAlreadyExistAndIsValid(stations):
    waitFor resolveAndDisplay(stations)
  else:
    readFromExistingStatusCache(stations)
