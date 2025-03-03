# utils.nim

import
  json, strutils, os,
  terminal, tables, times,

  ../audio/
    [
      player,
      libmpv,
    ],

  ../ui/illwill

from ../link/linkbase import normalizeUrl

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

type
  LinkStatus* = enum
    lsChecking, lsValid, lsInvalid

type
  MenuError* = object of CatchableError  # Custom error type for menu-related issues
  PlayerState* = object                   # Structure to hold the player's current state
    isPaused*: bool                       # Whether the player is paused
    isMuted*: bool                        # Whether the player is muted
    currentSong*: string                  # Currently playing song
    volume*: int                          # Current volume level

  MenuConfig* = object                    # Configuration for the menu and player
    ctx*: ptr Handle                      # Player handle
    currentSection*: string               # Current menu section
    currentSubsection*: string            # Current menu subsection
    stationName*: string                  # Name of the selected station
    stationUrl*: string                   # URL of the selected station

const
  CheckIdleInterval* = 25  # Interval to check if the player is idle
  KeyTimeout* = 25         # Timeout for key input in milliseconds

type
  Theme* = object
    header*: ForegroundColor
    separator*: ForegroundColor
    menu*: ForegroundColor
    footer*: ForegroundColor
    error*: ForegroundColor
    warning*: ForegroundColor
    success*: ForegroundColor
    nowPlaying*: ForegroundColor
    volumeLow*: ForegroundColor
    volumeMedium*: ForegroundColor
    volumeHigh*: ForegroundColor

type
  AnimationFrame* = object
    frame: int
    lastUpdate: DateTime

  PlayerStatus* = enum # Enumeration for player states
    StatusPlaying
    StatusMuted
    StatusPaused
    StatusPausedMuted

const
  AsciiFrames* = ["♪♫", "♫♪"] # ASCII fallback animation frames
  EmojiFrames* = ["🎵", "🎶"]     # Emoji animation frames

var
  animationFrame*: int = 0 # Tracks the current frame of the animation
  lastAnimationUpdate*: DateTime = now() # Tracks the last time the animation was updated

proc getSymbol*(status: PlayerStatus, useEmoji: bool): string =
  if useEmoji:
    case status
    of StatusPlaying:     "🔊"
    of StatusMuted:       "🔇"
    of StatusPaused:      "⏸"
    of StatusPausedMuted: "⏸ 🔇"
  else:
    case status
    of StatusPlaying:      "[>]"
    of StatusMuted:        "[X]"
    of StatusPaused:       "||"
    of StatusPausedMuted:  "||[X]"

var terminalSupportsEmoji* =
  when defined(noEmoji): false
  else: true

proc currentStatusEmoji*(status: PlayerStatus): string =
  return getSymbol(status, terminalSupportsEmoji)

when not defined(simple):
  type
    ThemeConfig* = object
      themes*: Table[string, Theme]
      currentTheme*: string


  var globalMetadata* {.global.}: Table[string, string]

  # Global variable to store emoji positions.  Each tuple is (x, y).
  var emojiPositions* = newSeqOfCap[(int, int)](32)

# Global variable to hold the current theme
var currentTheme*: Theme

var
  scrollOffset* = 0
  lastWidth* = 0
  startingX* = 0
  scrollCounter* = 0

const
  MenuChars* = "123456789ABCDEFGHIJKLMOPTVWXYZ"
  AppName* = "Poor Mans Radio Player"
  AppNameShort* = "PNimRP"
  DefaultErrorMsg* = "INVALID CHOICE"
  MinTerminalWidth* = 40
  MaxStationNameLength* = 22

var termWidth* = terminalWidth()  ## Tracks the current terminal width.
var lastMenuSeparatorY* {.global.}: int

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
  warnBell()
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
          "Station name at index " & $i & " ('" & result[i] & "') in file " & filePath & " is too long.",
          xOffset = 4,
          color = fgYellow
        )
        warn(
          "Maximum allowed length is " & $maxLength & " characters.",
          xOffset = 4,
          color = fgYellow
        )
        sleep(400)  # Pause for 400ms after displaying the warning
        warnCount += 1

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

proc appendToLikedSongs* =
  ## Appends a song to the likedSongs.txt file.
  const likedSongsFile = "likedSongs.txt"
  try:
    # Open the file in append mode (creates the file if it doesn't exist)
    let file = open(likedSongsFile, fmAppend)
    defer: file.close()
    
    # Append the song and a newline
    file.writeLine(fullMediaTitle)
    cursorDown 5
    warn("Song added to likedSongs.txt")  # Notify the user
    cursorUp()
    eraseLine()
    cursorUp 5
  except IOError as e:
    warn("Failed to save song to likedSongs.txt: " & e.msg)

proc truncateMe*(str: string): string =
  if str.len > int(terminalWidth().toFloat() / 1.65):
    result = str.substr(0, int(terminalWidth().toFloat() / 1.65)) & "..."
  else: return str
      #1.65 good factor to stop nowplaying overflow, inc 1.65 if does 

proc cleanupPlayer*(ctx: ptr Handle) =
  ## Cleans up player resources.
  #ctx.terminateDestroy()
  stopCurrentJob()

# Unit tests for utils.nim
when isMainModule:
  # Test parseJArray with the new stations format
  echo "Testing parseJArray with new stations format:"
  let stations = parseJArray("../assets/arab.json")
  echo "Parsed stations: ", stations
  echo ""

  # Test loadQuotes with the new quotes format
  echo "Testing loadQuotes with new quotes format:"
  let quotes = loadQuotes("../assets/config/qoute.json")
  echo "Parsed quotes: ", quotes.quotes
  echo "Parsed authors: ", quotes.authors
  echo ""
