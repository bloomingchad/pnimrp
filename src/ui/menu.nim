# menu.nim

import
  terminal, os, strutils, net,
  json, tables, random,

  ui, illwill,

  ../audio/[
      player,
      libmpv,
    ],

  ../link/link,
  ../utils/[
    utils,
    jsonutils
  ]

when not defined(simple):
  import asyncdispatch,

    ../audio/metadata,
    ../ui/[
      stationstatus,
      scroll,
      animation,
     ]


proc editBadFileHint(config: MenuConfig, extraMsg = "") =
  if extraMsg != "": warn(extraMsg)
  let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
  cursorDown 3
  warn("Failed to access station: " & config.stationName, delayMs = 0)
  warn("URL: " & config.stationUrl, delayMs = 0)
  warn("Edit station list in: " & fileHint & ".json", delayMs = 1350)
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

proc milSecToSec(ms: int): float = ms / 1000

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
    var scrollOffset: int = 0
    var lastWidth: int = 0
    var fullTitle: string # Declare fullTitle here

    when not defined(simple):
      var metadata = initTable[string, string](8) # Declare metadata here
      var scrollCounter: int = 0
      var animationCounter: int = 0  # Counter for animation updates
    

    allocateJobMpv(config.stationUrl)
    var event = mpvCtx.waitEvent()


    # Draw the initial player UI
    drawPlayerUI(config.stationName, "Loading...", currentStatusEmoji(currentStatus(state)), state.volume)
    showFooter(isPlayerUI = true)
    when defined(simple):
      fullTitle = fullTitle.truncateMe()

    while true:
      if not state.isPaused:
        const mpvEventLoopTimeout = KeyTimeout.milSecToSec
        event = mpvCtx.waitEvent(mpvEventLoopTimeout)

      # Handle playback events
      if event.eventID in {IDPlaybackRestart} and not isObserving:
        when not defined(simple): mpvCtx.observeMetadata()
        else: mpvCtx.observeMediaTitle()

        isObserving = true

      if event.eventID in {IDEventPropertyChange}:
        state.currentSong = mpvCtx.getCurrentMediaTitle()
        fullTitle = state.currentSong # Assign to fullTitle
        updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)
        when not defined(simple):
          globalMetadata = updateMetadataUI(config, mpvCtx, state)


      when not defined(simple):
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
          lastVolume = state.volume
          updateVolumePlayerUI(state.volume)

        of Key.Asterisk, Key.Minus:
          state.volume = max(state.volume - VolumeStep, MinVolume)
          cE mpvCtx.setProperty("volume", fmtInt64, addr state.volume)
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)
          lastVolume = state.volume
          
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


var chooseForMe* = false  # Declare as mutable global variable
var lastStationIdx*: int = -1  # Declare a global variable to track the last station index

proc chooseForMeOrChooseYourself(itemsLen: int): char =
  if chooseForMe:
    chooseForMe = false  # Reset the flag after use

    var rndIdx = rand(itemsLen - 1)  # Generate random index within bounds
    while rndIdx == lastStationIdx and itemsLen > 1:  # Ensure it doesn't pick the last station again
      rndIdx = rand(itemsLen - 1)
    lastStationIdx = rndIdx  # Update the last station index

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
              var subItems, subPaths = newSeqOfCap[string](32)

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
              let stations = loadStations(selectedPath)
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
