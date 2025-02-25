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

proc checkError(status: bool) =
  if not status:
    echo("cache error")
    quit(QuitFailure)

proc saveCache*(submenuName: string, cache: Cache): bool =
  ## Saves the cache data to a JSON file.
  ## Creates the cache directory if it doesn't exist.
  ## Uses robust JSON construction to avoid partial writes.
  
  let filePath = getCacheFilePath(submenuName)
  
  # Ensure the cache directory exists
  try:
    createDir(CacheDir)
  except OSError:
    stderr.writeLine fmt"Error: Failed to create cache directory '{CacheDir}'."
    return false
  
  # Prepare the JSON object
  var jsonObject = newJObject()
  jsonObject["last_check"] = %cache.lastCheck
  
  # Convert stations table to JSON
  var stationsObject = newJObject()
  for url, status in cache.stations.pairs:
    stationsObject[url] = %status
  jsonObject["stations"] = stationsObject
  
  # Write JSON to a temporary file first to avoid partial writes
  let tempFilePath = filePath & ".tmp"
  try:
    writeFile(tempFilePath, $jsonObject)
  except IOError:
    stderr.writeLine fmt"Error: Failed to write temporary cache file '{tempFilePath}'."
    return false
  
  # Move the temporary file to the actual cache file
  try:
    moveFile(tempFilePath, filePath)
  except OSError:
    stderr.writeLine fmt"Error: Failed to move temporary file to cache file '{filePath}'."
    return false
  
  return true


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
     checkError saveCache(submenuName, result)
