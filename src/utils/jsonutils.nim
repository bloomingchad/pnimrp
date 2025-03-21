import
  os, strutils,

  utilstypes

when defined(useJsmn):
  import ../json/jsmn
else:
  import json

proc loadCategories*(baseDir = getAppDir() / "assets"): tuple[names, paths: seq[string]] =
  ## Loads available station categories from the assets directory.
  result = (names: newSeqOfCap[string](32), paths: newSeqOfCap[string](32))

  let nativePath = baseDir / "*".unixToNativePath

  for file in walkFiles(nativePath):
    let filename = file.extractFilename

    # Skip qoute.json (exact match, case-sensitive)
    if filename == "qoute.json":
      continue

    # Add the file to names and paths
    let name = filename.changeFileExt("").capitalizeAscii
    result.names.add(name)
    result.paths.add(file)

  for dir in walkDirs(nativePath):
    let name = dir.extractFilename & DirSep
    if name == "config/": continue

    when defined(release) or defined(danger):
      if name == "deadStation/": continue

    result.names.add(name)
    result.paths.add(dir)


when defined(useJsmn):
  from privjsonjsmn import loadStationJSMN, loadQuotesJSMN
else:
  from privjsonstdlib import loadStationStdLib, loadQuotesStdLib


proc loadStations*(filePath: string): tuple[names, urls: seq[string]] =
  ## Parses a JSON file and returns station names and URLs.
  ##  - Normalizes URLs using linkbase.normalizeUrl.
  ##  - Raises `FileNotFoundError` if the file is not found.
  ##  - Raises `JSONParseError` if the JSON is invalid.
  try:
    when defined(useJsmn):
      return loadStationJSMN(filePath)
    else:
      return loadStationStdLib(filePath)
  except IOError:
    raise newException(FileNotFoundError, "Failed to load JSON file: " & filePath)

  except Exception as e:
    when defined(useJsmn):
      if e of JsmnException:
        raise newException(JSONParseError, "Failed to parse JSON file with JSMN: " & getCurrentExceptionMsg())
      else: discard
    else:
      raise newException(JSONParseError, "Failed to parse JSON file: " & filePath)

proc loadQuotes*(filePath: string): QuoteData =
  ## Loads and validates quotes from a JSON file.
  ## Raises `UIError` if the quote data is invalid.
  try:
    when defined(useJsmn):
      return loadQuotesJSMN(filePath)

    else:
      return loadQuotesStdLib(filePath)


  except IOError:
    raise newException(FileNotFoundError, "Failed to load quotes: " & filePath)
  except Exception as e:
    when defined(useJsmn):
      if e of JsmnException:
        raise newException(JSONParseError, "Failed to parse JSON file with JSMN: " & getCurrentExceptionMsg())
      else: discard
    else:
      raise newException(JSONParseError, "Failed to parse JSON file: " & filePath)
