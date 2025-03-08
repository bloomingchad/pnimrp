# statuscache.nim

import
  json, os, asyncdispatch,

  ../ui/stationstatus

let appDir = getAppDir()

#[
    {
        "lastChecked": "<stdanrd-datetime-format>",
        "stationlist": {
            "<name>": "ls<Status>",
            ...
        }
    }
]#

proc checkIfCacheDirExistElseCreate =
  if not appDir.dirExists:
    createDir appDir / ".statuscache"

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
