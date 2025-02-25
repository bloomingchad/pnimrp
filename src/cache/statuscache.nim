# cache.nim

import std/[json, times, os, strutils, tables, strformat],
  ../utils/utils,
  ../link/link,
  ../link/asynclink

const
  CacheTTL* = 86400  # 24 hours in seconds

let
  CacheDir* = getAppDir() / "assets" / ".stationstatuscache"

type
  Cache* = object
    lastCheck*: string # Using string for ISO 8601 representation
    stations*: Table[string, string]  # URL -> "valid" / "invalid"

proc getCacheFilePath*(submenuName: string): string =
  ## Constructs the full path to the cache file for a given submenu.
  result = CacheDir / ("cache_" & submenuName.toLowerAscii & ".json")

proc isFresh*(cache: Cache): bool =
  ## Checks if the cache is still fresh (within the TTL).
  try:
    if cache.lastCheck == "expired":
      return false
    let lastCheckTime = parse(cache.lastCheck, "yyyy-MM-dd'T'HH:mm:ss'Z'")
    let currentTime = now()
    let diffSeconds = (currentTime - lastCheckTime).inSeconds
    return diffSeconds <= CacheTTL
  except ValueError: # Catch date parsing errors
    stderr.writeLine "Error: Invalid date format in cache. Treating as expired."
    return false

proc loadCache*(submenuName: string): Cache =
  ## Loads the cache from the JSON file.  Handles file not found and parsing errors.
  let filePath = getCacheFilePath(submenuName)
  result = Cache(lastCheck: "expired", stations: initTable[string, string]()) # Initialize with an expired timestamp

  if fileExists(filePath):
    try:
      let jsonData = parseFile(filePath)
      result.lastCheck = jsonData["last_check"].getStr()

      # Use a try-except block to handle potential key errors or type mismatches.
      try:
          if jsonData.hasKey("stations") and jsonData["stations"].kind == JObject:
              for url, statusStr in jsonData["stations"].pairs:
                  # Validate that statusStr is either "valid" or "invalid"
                  if statusStr.getStr() in ["valid", "invalid"]:
                      result.stations[url] = statusStr.getStr()
                  else:
                      stderr.writeLine fmt"Warning: Invalid status value '{statusStr}' for URL '{url}' in cache file '{filePath}'. Skipping."
          else:
              stderr.writeLine fmt"Warning: 'stations' key is missing or not a JSON object in cache file '{filePath}'."
      except KeyError:
          stderr.writeLine fmt"Warning: 'stations' key is missing in cache file '{filePath}'."
      #except TypeError:
      #     stderr.writeLine fmt"Warning: Unexpected data type encountered while parsing cache file '{filePath}'."

    except JsonParsingError:
      stderr.writeLine fmt"Error: Failed to parse JSON in cache file: " & filePath
      # Consider deleting the corrupt file: removeFile(filePath)
    except IOError:
      stderr.writeLine fmt"Error: Failed to read cache file: " & filePath
  else:
     #Initialize file to not repeat checks
     saveCache(submenuName, result)
