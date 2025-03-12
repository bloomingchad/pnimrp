# utils.nim

import
  json, os, terminal,

  ../audio/
    [
      player,
      libmpv,
    ],

  ../ui/illwill,

  utilstypes,
  uiutils,
  jsonutils

let appDir* = getAppDir()

proc checkIfCacheDirExistElseCreate* =
  let statusCache = appDir / ".statuscache"
  if not dirExists statusCache:
    createDir statusCache

proc validateLengthStationName*(result: seq[string], filePath: string, maxLength: int = MaxStationNameLength) =
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

  finally:
    stdout.flushFile()

proc checkIfTooLongForUI*(str: string): bool = 
  str.len > int(terminalWidth().toFloat() / 1.65)

proc truncateMe*(str: string): string =
  if str.checkIfTooLongForUI():
    result = str.substr(0, int(terminalWidth().toFloat() / 1.65)) & "..."
  else: return str
      #1.65 good factor to stop nowplaying overflow, inc 1.65 if does 

proc initCheckingStationNotice* =
  setCursorPos(2, lastMenuSeparatorY + 6)
  stdout.write "Checking stations... Please Wait"
  stdout.flushFile()

proc finishCheckingStationNotice* = 
  setCursorPos 2, lastMenuSeparatorY + 6
  eraseLine()
  lastMenuSeparatorY = 0
  stdout.flushFile()

proc cleanupPlayer*(ctx: ptr Handle) =
  ## Cleans up player resources.
  #ctx.terminateDestroy()
  stopCurrentJob()

export #jsonutils
  loadCategories, loadStations, loadQuotes

export #uiutils
  getSymbol, terminalSupportsEmoji, currentStatusEmoji,
  error, updateTermWidth, clear, warn, showInvalidChoice,
  centerText, showSpinner, truncateName, calculateColumnLayout

#export all internal within utils namespace 
export #utilstypes
  QuoteData, 

  UIError, JSONParseError, FileNotFoundError,
  ValidationError, InvalidDataError,

  MenuOptions,
  LinkStatus,
  MenuError,
  PlayerState,
  MenuConfig,

  CheckIdleInterval,
  KeyTimeout,

  Theme,

  AnimationFrame,
  PlayerStatus,

  termWidth,
  lastMenuSeparatorY,

  AsciiFrames,
  EmojiFrames,

  animationFrame,
  lastAnimationUpdate,

  currentTheme,

  scrollOffset,
  lastWidth,
  startingX,
  scrollCounter,

  MenuChars,
  AppName,
  AppNameShort,
  DefaultErrorMsg,
  MinTerminalWidth,
  MaxStationNameLength

when not defined(simple):
  export #utilstypes
    ThemeConfig,
    globalMetadata,
    emojiPositions
