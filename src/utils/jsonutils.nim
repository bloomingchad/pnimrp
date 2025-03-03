import
  os, strutils, json,

  utilstypes

from ../link/linkbase import normalizeUrl

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
    result.names.add(name)
    result.paths.add(dir)

proc loadStations*(filePath: string): tuple[names, urls: seq[string]] =
  ## Parses a JSON file and returns station names and URLs.
  ##  - Normalizes URLs using linkbase.normalizeUrl.
  ##  - Raises `FileNotFoundError` if the file is not found.
  ##  - Raises `JSONParseError` if the JSON is invalid.
  try:
    let jsonData = parseJson(readFile(filePath))

    if not jsonData.hasKey("stations"):
      raise newException(JSONParseError, "Missing 'stations' key in JSON file.")

    let stations = jsonData["stations"]
    result = (names: newSeq[string](), urls: newSeq[string]())

    for stationName, stationUrlNode in stations.pairs:
      let stationNameStr = stationName
      let stationUrlStr = stationUrlNode.getStr

      # Normalize the URL using linkbase.normalizeUrl
      let normalizedUrl = normalizeUrl(stationUrlStr)

      result.names.add(stationNameStr)
      result.urls.add(normalizedUrl)  # Add the *normalized* URL

    # Validate station names (only if it's not the quotes file)
    #if not filePath.endsWith("qoute.json"):
      #validateLengthStationName(result.names, filePath)

  except IOError:
    raise newException(FileNotFoundError, "Failed to load JSON file: " & filePath)
  except JsonParsingError:
    raise newException(JSONParseError, "Failed to parse JSON file: " & filePath)

proc loadQuotes*(filePath: string): QuoteData =
  ## Loads and validates quotes from a JSON file.
  ## Raises `UIError` if the quote data is invalid.
  try:
    let jsonData = parseJson(readFile(filePath))
    
    # Check if the JSON is an object (for the new format)
    if jsonData.kind != JObject:
      raise newException(InvalidDataError, "Invalid JSON format: expected an object.")
    
    result = QuoteData(quotes: newSeqOfCap[string](32), authors: newSeqOfCap[string](32))  # Initialize empty sequences
    
    # Iterate over the key-value pairs in the JSON object
    for quote, author in jsonData.pairs:
      result.quotes.add(quote)        # Add the quote (key)
      result.authors.add(author.getStr)  # Add the author (value, converted to string)
    
    # Validate quotes and authors
    for i in 0 ..< result.quotes.len:
      if result.quotes[i].len == 0:
        raise newException(InvalidDataError, "Empty quote found at index " & $i)
      if result.authors[i].len == 0:
        raise newException(InvalidDataError, "Empty author found for quote at index " & $i)
        
  except IOError:
    raise newException(FileNotFoundError, "Failed to load quotes: " & filePath)
  except JsonParsingError:
    raise newException(JSONParseError, "Failed to parse quotes: " & filePath)
