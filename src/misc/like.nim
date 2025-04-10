# SPDX-License-Identifier: MPL-2.0
import
  terminal, times,

  ../utils/utils, ../audio/player

proc appendToFileReUsable(filen: string, config: MenuConfig, isLike: bool) =
  ## Appends a song to the likedSongs.txt file.
  try:
    # Open the file in append mode (creates the file if it doesn't exist)
    let file = open(filen, fmAppend)
    defer: file.close()

    # Append the song and a newline

    file.writeLine(
        getDateStr()  &  " | "  &
        getClockStr() &  " | "  &
        config.currentSection   & " | " &
        config.stationName      & " | " &
      fullMediaTitle
    )
    if isLike:
      cursorDown 5
      warn("Song added to likedSongs.txt") # Notify the user
      cursorUp()
      eraseLine()
      cursorUp 5

  except IOError as e:
    warn("Failed to save song to likedSongs.txt: " & e.msg)

  finally:
    stdout.flushFile()

template appendToLikedSongs*(config: MenuConfig) =
  appendToFileReUsable("likedSongs.txt", config, isLike = true)

template appendToHistory*(config: MenuConfig) =
  appendToFileReUsable("history.txt", config, isLike = false)
