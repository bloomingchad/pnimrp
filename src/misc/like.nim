import
  terminal, times,

  ../utils/utils, ../audio/player

proc appendToLikedSongs*(sectionName: string) =
  ## Appends a song to the likedSongs.txt file.
  const likedSongsFile = "likedSongs.txt"
  try:
    # Open the file in append mode (creates the file if it doesn't exist)
    let file = open(likedSongsFile, fmAppend)
    defer: file.close()

    # Append the song and a newline

    file.writeLine(
      "[" & getDateStr()  & "]"  &
      "[" & getClockStr() & "] " &
            sectionName   & " " &
      fullMediaTitle
      )
    cursorDown 5
    warn("Song added to likedSongs.txt") # Notify the user
    cursorUp()
    eraseLine()
    cursorUp 5

  except IOError as e:
    warn("Failed to save song to likedSongs.txt: " & e.msg)

  finally:
    stdout.flushFile()

