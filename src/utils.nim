import
  json, strutils, os, terminal

type
  QuoteData* = object
    quotes*: seq[string]
    authors*: seq[string]

  UIError* = object of CatchableError

  MenuOptions* = seq[string]

  PlayerStatus* = enum  # Enumeration for player states
    StatusPlaying
    StatusMuted
    StatusPaused
    StatusPausedMuted

const
  # Characters for menu options
  MenuChars* = @[
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ]
  AppName* = "Poor Mans Radio Player"
  AppNameShort* = "PNimRP"
  DefaultErrorMsg* = "INVALID CHOICE"
  MinTerminalWidth* = 40

var termWidth* = terminalWidth()

proc error*(message: string) =
  ## Displays error message and exits program
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc updateTermWidth* =
  ## Updates the terminal width only if it has changed.
  let newWidth = terminalWidth()
  if newWidth != termWidth:
    termWidth = newWidth

proc clear* =
  ## Clears the screen and resets cursor position
  eraseScreen()
  setCursorPos(0, 0)

proc warn*(message: string, xOffset = 4, color = fgRed) =
  ## Displays warning message with delay
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  sleep(750)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Shows invalid choice message and repositions cursor
  cursorDown(5)
  warn(message)
  cursorUp()
  eraseLine()
  cursorUp(5)

const MaxStationNameLength = 22

proc validateLengthStationName(result: seq[string], str: string) =
  # Validate the length of station names (odd indices)
  var warnCount = 0
  for i in 0 ..< result.len:
    if warnCount == 3: break
    if i mod 2 == 0:  # Only validate odd indices (0, 2, 4, ...)
      if result[i].len > MaxStationNameLength:
        warn(
          "Station name at index \"" & result[i] & "\" in file " & str & " is too long. ",
          xOffset = 4,
          color = fgYellow
        )
        warn(
          "Maximum allowed length is " & $MaxStationNameLength & " characters.",
          xOffset = 4,
          color = fgYellow
        )
          
        sleep(400)  # Pause for 500ms after displaying the warning
    warnCount += 1

proc parseJArray*(str: string): seq[string] =
  ## Parses a JSON array from a file and validates the length of station names (odd indices).
  ## Warns if any station name exceeds the maximum allowed length but continues processing.
  # Maximum allowed length for station names

  try:
    # Parse the JSON file and extract the array
    result = to(parseJson(readFile(str)){"pnimrp"}, seq[string])
    if not str.endsWith("qoute.json"): validateLengthStationName(result, str)

  except IOError:
    raise newException(UIError, "Failed to load JSON file: File not found or inaccessible.")

  except JsonParsingError:
    raise newException(UIError, "Failed to parse JSON file: Invalid JSON format.")

proc loadQuotes*(filePath: string): QuoteData =
  ## Loads and validates quotes from a JSON file.
  try:
    let jsonData = parseJArray(filePath)
    if jsonData.len mod 2 != 0:
      raise newException(UIError, "Quote data must have matching quotes and authors")
    
    result = QuoteData(quotes: @[], authors: @[])
    for i in 0 .. jsonData.high:
      if i mod 2 == 0:
        result.quotes.add(jsonData[i])
      else:
        result.authors.add(jsonData[i])
        
    # Validate quotes and authors
    for i in 0 ..< result.quotes.len:
      if result.quotes[i].len == 0:
        raise newException(UIError, "Empty quote found at index " & $i)
      if result.authors[i].len == 0:
        raise newException(UIError, "Empty author found for quote at index " & $i)
        
  except IOError:
    raise newException(UIError, "Failed to load quotes: File not found")
  except JsonParsingError:
    raise newException(UIError, "Failed to parse quotes: Invalid JSON format")