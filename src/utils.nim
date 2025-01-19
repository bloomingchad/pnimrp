import
  json, strutils, os, terminal,
  sequtils, strformat, times

type
  QuoteData* = object
    quotes*: seq[string]
    authors*: seq[string]

  UIError* = object of CatchableError
  JSONParseError* = object of UIError
  FileNotFoundError* = object of UIError
  ValidationError* = object of UIError
  InvalidDataError* = object of UIError

  MenuOptions* = seq[string]

const
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
  MaxStationNameLength* = 22

var termWidth* = terminalWidth()  ## Tracks the current terminal width.

proc error*(message: string) =
  ## Displays an error message and exits the program.
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc updateTermWidth* =
  ## Updates the terminal width only if it has changed.
  let newWidth = terminalWidth()
  if newWidth != termWidth:
    termWidth = newWidth

proc clear* =
  ## Clears the screen and resets the cursor position.
  eraseScreen()
  setCursorPos(0, 0)

proc warn*(message: string, xOffset = 4, color = fgYellow, delayMs = 750) =
  ## Displays a warning message with a delay.
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  sleep(delayMs)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Shows an invalid choice message and repositions the cursor.
  cursorDown(5)
  warn(message, color = fgRed)
  cursorUp()
  eraseLine()
  cursorUp(5)

proc validateLengthStationName(result: seq[string], filePath: string, maxLength: int = MaxStationNameLength) =
  ## Validates the length of station names (odd indices).
  ## Raises a `ValidationError` if any station name exceeds the maximum allowed length.
  var warnCount = 0
  for i in 0 ..< result.len:
    if warnCount == 3: break
    if i mod 2 == 0:  # Only validate odd indices (0, 2, 4, ...)
      if result[i].len > maxLength:
        warn(
          fmt"Station name at index {i} ('{result[i]}') in file {filePath} is too long.",
          xOffset = 4,
          color = fgYellow
        )
        warn(
          fmt"Maximum allowed length is {maxLength} characters.",
          xOffset = 4,
          color = fgYellow
        )
        sleep(400)  # Pause for 400ms after displaying the warning
        warnCount += 1

proc parseJArray*(filePath: string): seq[string] =
  ## Parses a JSON array from a file and validates the length of station names (odd indices).
  ## Raises `FileNotFoundError` if the file is not found or inaccessible.
  ## Raises `JSONParseError` if the JSON format is invalid.
  try:
    let jsonData = parseJson(readFile(filePath))
    if not jsonData.hasKey("pnimrp"):
      raise newException(JSONParseError, "Missing 'pnimrp' key in JSON file.")
    
    result = jsonData["pnimrp"].to(seq[string])
    if not filePath.endsWith("qoute.json"):
      validateLengthStationName(result, filePath)

  except IOError:
    raise newException(FileNotFoundError, fmt"Failed to load JSON file: {filePath}")
  except JsonParsingError:
    raise newException(JSONParseError, fmt"Failed to parse JSON file: {filePath}")

proc loadQuotes*(filePath: string): QuoteData =
  ## Loads and validates quotes from a JSON file.
  ## Raises `UIError` if the quote data is invalid.
  try:
    let jsonData = parseJArray(filePath)
    if jsonData.len mod 2 != 0:
      raise newException(InvalidDataError, "Quote data must have matching quotes and authors")
    
    result = QuoteData(quotes: @[], authors: @[])
    for i in 0 .. jsonData.high:
      if i mod 2 == 0:
        result.quotes.add(jsonData[i])
      else:
        result.authors.add(jsonData[i])
        
    # Validate quotes and authors
    for i in 0 ..< result.quotes.len:
      if result.quotes[i].len == 0:
        raise newException(InvalidDataError, fmt"Empty quote found at index {i}")
      if result.authors[i].len == 0:
        raise newException(InvalidDataError, fmt"Empty author found for quote at index {i}")
        
  except IOError:
    raise newException(FileNotFoundError, fmt"Failed to load quotes: {filePath}")
  except JsonParsingError:
    raise newException(JSONParseError, fmt"Failed to parse quotes: {filePath}")

proc centerText*(text: string, width: int = termWidth): string =
  ## Centers the given text within the specified width.
  let padding = (width - text.len) div 2
  result = " ".repeat(max(0, padding)) & text

proc showSpinner*(delayMs: int = 100) =
  ## Displays a simple spinner animation.
  const spinner = @["-", "\\", "|", "/"]
  var frame = 0
  while true:
    stdout.write("\r" & spinner[frame] & " Working...")
    stdout.flushFile()
    frame = (frame + 1) mod spinner.len
    sleep(delayMs)

# Unit tests for utils.nim
when isMainModule:
  import unittest

  suite "Utils Tests":
    test "centerText":
      check centerText("Hello", 10) == "  Hello   "
      check centerText("Hello", 5) == "Hello"
      check centerText("Hello", 3) == "Hello"

    test "parseJArray":
      let testJson = """{"pnimrp": ["Station1", "http://example.com", "Station2", "http://example2.com"]}"""
      writeFile("test.json", testJson)
      let parsed = parseJArray("test.json")
      check parsed == @["Station1", "http://example.com", "Station2", "http://example2.com"]
      removeFile("test.json")

    test "loadQuotes":
      let testJson = """{"pnimrp": ["Quote1", "Author1", "Quote2", "Author2"]}"""
      writeFile("test_quotes.json", testJson)
      let quotes = loadQuotes("test_quotes.json")
      check quotes.quotes == @["Quote1", "Quote2"]
      check quotes.authors == @["Author1", "Author2"]
      removeFile("test_quotes.json")