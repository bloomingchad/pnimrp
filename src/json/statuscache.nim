# statuscache.nim

import
  json, os, asyncdispatch, ../utils/utils, terminal,

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

proc checkIfCacheAlreadyExistAndIsValid*(stations): bool = false #dummy

proc initBaseJsonCache() = discard

proc saveStatusCacheToJson(stations) =
  var fileInConsideration: File

  discard open(fileInConsideration, stations[0].fileName, fmWrite)

  initBaseJsonCache()

  #[
    for station in stations:
      json.add("station" : "bool(status")
  ]#

proc readFromExistingStatusCache*(stations) = discard

proc hookCacheResolveAndDisplay*(stations) =
  when defined(expstatuscache):
    if not checkIfCacheAlreadyExistAndIsValid(stations):
      waitFor resolveAndDisplay(stations)
      saveStatusCacheToJson(stations)
    else:
      readFromExistingStatusCache(stations)
  else:
    waitFor resolveAndDisplay(stations)
