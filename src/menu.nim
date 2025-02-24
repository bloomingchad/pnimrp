# menu.nim

import
  terminal, os, ui, strutils, libmpv,
  net, player, link, illwill, utils,
  animation, json, tables, scroll,
  random

when not defined(simple):
  import metadata, stationstatus, asyncdispatch

proc editBadFileHint(config: MenuConfig, extraMsg = "") =
  if extraMsg != "": warn(extraMsg)
  let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
  cursorDown 3
  warn(
      "Failed to access station: " & config.stationUrl &
      "\nEdit the station list in: " & fileHint & ".json",
    delayMs = 1350
  )
  cursorUp 5

proc handlePlayerError(msg: string; config: MenuConfig; shouldReturn = false) =
  ## Handles player errors consistently and optionally destroys the player context.
  editBadFileHint(config, msg)
  if shouldReturn:
    return

proc currentStatus(state: PlayerState): PlayerStatus =
  if not state.isPaused and not state.isMuted: StatusPlaying
  elif not state.isPaused and state.isMuted: StatusMuted
  elif state.isPaused and not state.isMuted: StatusPaused
  else:                                      StatusPausedMuted

proc isValidPlaylistUrl(url: string): bool =
  ## Checks if the URL points to a valid playlist format (.pls or .m3u).
  result = url.endsWith(".pls") or url.endsWith(".m3u")

proc updateAnimationOnly(status, currentSong: string, animationCounter: int) =
  ## Updates only the animation symbol in the "Now Playing" section.
  ##
  ## Args:
  ##   status: The player status (e.g., "🔊" for playing).
  ##   currentSong: The currently playing song.
  ##   animationCounter: The current counter value (incremented every 25ms).
  let animationSymbol = updateJinglingAnimation(status, animationCounter)  # Get the animation symbol

  # Move the cursor to the start of the "Now Playing" line (line 2)
  setCursorPos(0, 2)
  
  # Write ONLY the animation symbol and 3 spaces, then erase to the end of the line
  styledEcho(fgCyan, animationSymbol)

proc cleanupPlayer(ctx: ptr Handle) =
  ## Cleans up player resources.
  #ctx.terminateDestroy()
  illwillDeinit()
  stopCurrentJob()

proc playStation(config: MenuConfig) =
    ## Plays a radio station and handles user input for playback control.
    #try:
    if config.stationUrl == "":
      editBadFileHint(config)
      return

    # Validate the link
    try:
      if not validateLink(config.stationUrl).isValid:
        editBadFileHint(config)
        return
    except Exception:
      editBadFileHint(config)
      return

    var state = PlayerState(isPaused: false, isMuted: false, volume: lastVolume)  # Use lastVolume
    var isObserving = false
    var counter: uint8
    var playlistFirstPass = false
    var animationCounter: int = 0  # Counter for animation updates
    var scrollOffset: int = 0
    var lastWidth: int = 0
    var scrollCounter: int = 0
    var fullTitle: string # Declare fullTitle here
    var metadata: Table[string, string] # Declare metadata here

    allocateJobMpv(config.stationUrl)
    var event = mpvCtx.waitEvent()

    try:
      illwillInit(false)
    except:
      discard  # Non-critical failure

    # Draw the initial player UI
    drawPlayerUI(config.stationName, "Loading...", currentStatusEmoji(currentStatus(state)), state.volume)
    showFooter(isPlayerUI = true)

    while true:
      if not state.isPaused:
        event = mpvCtx.waitEvent()

      # Handle playback events
      if event.eventID in {IDPlaybackRestart} and not isObserving:
        mpvCtx.observeMediaTitle()
        cE(observeProperty(mpvCtx, 0, "metadata", fmtNone))
        isObserving = true

      if event.eventID in {IDEventPropertyChange}:
        state.currentSong = mpvCtx.getCurrentMediaTitle()
        fullTitle = state.currentSong # Assign to fullTitle
        updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)
        when not defined(simple):
          globalMetadata = updateMetadataUI(config, mpvCtx, state)

      # Increment the animation counter every 25ms (getKeyWithTimeout interval)
      animationCounter += 1

      # Check if it's time to update the animation (1350ms / 25ms = 54 iterations)
      if animationCounter >= 54:
        updateAnimationOnly(currentStatusEmoji(currentStatus(state)), state.currentSong, animationCounter)
        animationCounter = 0  # Reset the counter

      # Scrolling Logic
      if scrollCounter == 21:
        scrollTextOnce(fullTitle, scrollOffset, termWidth, startingX) # Corrected call
        if fullTitle.len > termWidth - startingX:
          scrollOffset += 1
        scrollCounter = 0
      else:
        scrollCounter += 1

      # Periodic checks
      if counter >= CheckIdleInterval:
        if mpvCtx.isIdle():
          handlePlayerError("Player core idle", config)
          break

        if event.eventID in {IDEndFile, IDShutdown}:
          if config.stationUrl.isValidPlaylistUrl():
            if playlistFirstPass:
              handlePlayerError("End of playlist reached", config)
              break
            playlistFirstPass = true
          else:
            handlePlayerError("Stream ended", config)
            break
        counter = 0
      inc counter

      # Handle user input
      case getKeyWithTimeout(KeyTimeout):
        of Key.P:
          state.isPaused = not state.isPaused
          mpvCtx.pause(state.isPaused)
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.M:
          state.isMuted = not state.isMuted
          mpvCtx.mute(state.isMuted)
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.Slash, Key.Plus:
          state.volume = min(state.volume + VolumeStep, MaxVolume)
          cE mpvCtx.setProperty("volume", fmtInt64, addr state.volume)
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.Asterisk, Key.Minus:
          state.volume = max(state.volume - VolumeStep, MinVolume)
          cE mpvCtx.setProperty("volume", fmtInt64, addr state.volume)
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.R:
          if not state.isPaused:
            cleanupPlayer(mpvCtx)
          stopCurrentJob()
          break

        of Key.Q:
          cleanupPlayer(mpvCtx)
          exit(mpvCtx, state.isPaused)

        of Key.L:  # New key binding for "Like" action
          if state.currentSong != "":
            appendToLikedSongs()
          else:
            warn("No song is currently playing.")

        of Key.None:
          continue

        else:
          showInvalidChoice()
    lastVolume = state.volume #update last state volume to be persistent

  #except Exception:
  #  let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
  #  warn("An error occurred during playback. Edit the station list in: " & fileHint & ".json")
  #  cleanupPlayer(mpvCtx)
  #  return


proc showHelp*() =
  ## Displays instructions on how to use the app.
  clear()
  drawHeader("Help")
  say("Welcome to " & AppName & "!", fgYellow)
  say("Here's how to use the app:", fgGreen)
  say("1. Use the number keys (1-9) or letters (A-Z) to select a station.", fgBlue)
  say("2. In the player UI, use the following keys:", fgBlue)
  say("   - [P] Pause/Play", fgBlue)
  say("   - [-/+] Adjust Volume", fgBlue)
  say("   - [R] Return to the previous menu", fgBlue)
  say("   - [Q] Quit the application", fgBlue)
  say("3. Press [N] in the main menu to view notes.", fgBlue)
  say("4. Press [H] in the main menu to view this help screen.", fgBlue)
  say("=".repeat(termWidth), fgGreen, xOffset = 0)
  say("Press any key to return to the main menu.", fgYellow)
  discard getch()  # Wait for any key press

proc loadStationList(jsonPath: string): tuple[names, urls: seq[string]] =
  ## Loads station names and URLs from a JSON file.
  ## If a URL does not have a protocol prefix (e.g., "http://"), it defaults to "http://".
  try:
    let jsonData = parseJson(readFile(jsonPath))
    
    # Check if the "stations" key exists
    if not jsonData.hasKey("stations"):
      raise newException(MenuError, "Missing 'stations' key in JSON file.")
    
    let stations = jsonData["stations"]
    result = (names: @[], urls: @[])
    
    # Iterate over the stations and add names and URLs
    for stationName, stationUrl in stations.pairs:
      result.names.add(stationName)  # Add station name (key)
      
      # Ensure the URL has a protocol prefix
      let url = 
        if stationUrl.getStr.startsWith("http://") or stationUrl.getStr.startsWith("https://"):
          stationUrl.getStr  # Use the URL as-is
        else:
          "http://" & stationUrl.getStr  # Prepend "http://" if no protocol is specified
      
      result.urls.add(url)  # Add the processed URL
    
    # Validate that we have at least one station
    if result.names.len == 0 or result.urls.len == 0:
      raise newException(MenuError, "No stations found in the JSON file.")
    
  except IOError:
    raise newException(MenuError, "Failed to read JSON file: " & jsonPath)
  except JsonParsingError:
    raise newException(MenuError, "Failed to parse JSON file: " & jsonPath)
  except Exception as e:
    raise newException(MenuError, "An error occurred while loading the station list: " & e.msg)

proc loadCategories*(baseDir = getAppDir() / "assets"): tuple[names, paths: seq[string]] =
  ## Loads available station categories from the assets directory.
  result = (names: @[], paths: @[])
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

var chooseForMe = false  # Declare as mutable global variable

proc chooseForMeOrChooseYourself(itemsLen: int): char =
  if chooseForMe:
    chooseForMe = false  # Reset the flag after use
    randomize()
    let rndIdx = rand(itemsLen - 1)  # Generate random index within bounds

    # Convert the random index to a menu key (1-9, A-M)
    result = 
      if rndIdx < 9: chr(ord('1') + rndIdx)
      else: chr(ord('A') + rndIdx - 9)
  else:
    return getch()

type
  handleMenuIsHandling = enum
    hmIsHandlingDirectory,
    hmIsHandlingUrl,
    hmIsHandlingJson

proc isHandlingJSON(state: handleMenuIsHandling): bool =
  if state == hmIsHandlingJson: true else: false

proc handleMenu*(
  section: string,
  items: seq[string],
  paths: seq[string],
  isMainMenu: bool = false,
  baseDir: string = getAppDir() / "assets",
  handleMenuIsHandling: handleMenuIsHandling
) =
  ## Handles a generic menu for station selection or main category selection.
  ## Supports both directories and JSON files.
  while true:
    var returnToParent = false
    clear()
    drawHeader()
    
    # Display the menu
    drawMenu(section, items, isMainMenu = isMainMenu, isPlayerUI = false, isHandlingJSON = isHandlingJSON(handleMenuIsHandling))  # Pass isPlayerUI here
    hideCursor()

    when not defined(simple):
      if isHandlingJSON(handleMenuIsHandling):
        initCheckingStationNotice()

        var stations: seq[StationStatus] = @[]
        for i in 0..<items.len:
          stations.add(
            StationStatus(
              coord: emojiPositions[i],  # From ui.nim
              url: paths[i],             # Station URL
              status: lsChecking         # Initial state
            )
          )

        waitFor resolveAndDisplay(stations)  # Defined in stationstatus.nim

        finishCheckingStationNotice()

    while true:
      try:
        let key = chooseForMeOrChooseYourself(items.len)
        case key
        of '1'..'9', 'A'..'M', 'a'..'m':
          let idx = 
            if key in {'1'..'9'}: ord(key) - ord('1')
            else: ord(toLowerAscii(key)) - ord('a') + 9
          
          if idx >= 0 and idx < items.len:
            let selectedPath = paths[idx]
            if dirExists(selectedPath):
              # Handle directories (subcategories or station lists)
              var subItems: seq[string] = @[]
              var subPaths: seq[string] = @[]
              for file in walkFiles(selectedPath / "*.json"):
                let name = file.extractFilename.changeFileExt("").capitalizeAscii
                subItems.add(name)
                subPaths.add(file)
              if subItems.len == 0:
                warn("No station lists available in this category.")
              else:
                # Navigate to subcategories with isMainMenu = false
                handleMenu(items[idx], subItems, subPaths, isMainMenu = false, baseDir = baseDir, handleMenuIsHandling = hmIsHandlingDirectory)
            elif fileExists(selectedPath) and selectedPath.endsWith(".json"):
              # Handle JSON files (station lists)
              let stations = loadStationList(selectedPath)
              if stations.names.len == 0 or stations.urls.len == 0:
                warn("No stations available. Please check the station list.")
              else:
                # Navigate to station list with isMainMenu = false
                handleMenu(items[idx], stations.names, stations.urls, isMainMenu = false, baseDir = baseDir, handleMenuIsHandling = hmIsHandlingJSON)
            else:
              # Treat as a station URL and play directly
              let config = MenuConfig(
                currentSection: section,
                currentSubsection: "",
                stationName: items[idx],
                stationUrl: selectedPath
              )
              playStation(config)
            break
          else:
            showInvalidChoice()

        of 'N', 'n':
          if isMainMenu:  # Only allow Notes in the main menu
            showNotes()
            break
          else:
            showInvalidChoice()

        of 'U', 'u':
          showHelp()
          break

        of 'R', 'r':
          if not isMainMenu or baseDir != getAppDir() / "assets":
            returnToParent = true
            break
          else:
            showInvalidChoice()
        of 'S', 's':
          chooseForMe = true

        of 'Q', 'q':
          showExitMessage()
          break

        else:
          showInvalidChoice()

      except IndexDefect:
        showInvalidChoice()

    if returnToParent:
      break

proc drawMainMenu*(baseDir = getAppDir() / "assets") =
  ## Draws and handles the main category menu.
  let categories = loadCategories(baseDir)
  handleMenu("Main", categories.names, categories.paths, isMainMenu = true, baseDir = baseDir, handleMenuIsHandling = hmIsHandlingDirectory)

export hideCursor, error

when isMainModule:
  try:
    drawMainMenu()
  except MenuError as e:
    error("Menu error: " & e.msg)
