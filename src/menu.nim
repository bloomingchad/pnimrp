import
  terminal, os, ui, strutils, times,
  client, net, player, link, illwill,
  utils, animation

type
  MenuError* = object of CatchableError  # Custom error type for menu-related issues
  PlayerState = object                   # Structure to hold the player's current state
    isPaused: bool                       # Whether the player is paused
    isMuted: bool                        # Whether the player is muted
    currentSong: string                  # Currently playing song
    volume: int                          # Current volume level

  MenuConfig = object                    # Configuration for the menu and player
    ctx: ptr Handle                      # Player handle
    currentSection: string               # Current menu section
    currentSubsection: string            # Current menu subsection
    stationName: string                  # Name of the selected station
    stationUrl: string                   # URL of the selected station

const
  CheckIdleInterval = 25  # Interval to check if the player is idle
  KeyTimeout = 25         # Timeout for key input in milliseconds

proc handlePlayerError(msg: string, ctx: ptr Handle = nil, shouldReturn = false) =
  ## Handles player errors consistently and optionally destroys the player context.
  warn(msg)
  if ctx != nil:
    ctx.terminateDestroy()
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

proc updateAnimationOnly(status, currentSong: string) =
  ## Updates only the animation symbol in the "Now Playing" section.
  let animationSymbol = updateJinglingAnimation(status)  # Get the animation symbol
  setCursorPos(0, 2)  # Move cursor to the "Now Playing" line
  eraseLine()  # Clear the current line

  # Display the animation symbol and "Now Playing" text in cyan
  styledEcho(fgCyan, animationSymbol & " Now Playing: ", fgCyan, currentSong)

proc playStation(config: MenuConfig) =
  ## Plays a radio station and handles user input for playback control.
  try:
    if config.stationUrl == "":
      let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
      warn("Empty station URL. Please check the station list in: " & fileHint & ".json")
      return

    # Validate the link
    try:
      if not validateLink(config.stationUrl).isValid:
        let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
        warn("Failed to access station: " & config.stationUrl & "\nEdit the station list in: " & fileHint & ".json")
        return
    except Exception:
      let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
      warn("Failed to access station: " & config.stationUrl & "\nEdit the station list in: " & fileHint & ".json")
      return

    var
      ctx = create()
      state = PlayerState(isPaused: false, isMuted: false, volume: 100)
      isObserving = false
      counter: uint8
      playlistFirstPass = false
      lastAnimationUpdate: DateTime = now()  # Track the last animation update time

    ctx.init(config.stationUrl)
    var event = ctx.waitEvent()

    try:
      illwillInit(false)
    except:
      discard  # Non-critical failure

    # Draw the initial player UI
    drawPlayerUI(config.stationName, "Loading...", currentStatusEmoji(currentStatus(state)), state.volume)

    while true:
      if not state.isPaused:
        event = ctx.waitEvent()

      # Handle playback events
      if event.eventID in {IDPlaybackRestart} and not isObserving:
        ctx.observeMediaTitle()
        isObserving = true

      if event.eventID in {IDEventPropertyChange}:
        state.currentSong = ctx.getCurrentMediaTitle()
        # Update the full UI only when the song name changes
        updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

      # Check if it's time to update the animation (2 FPS = every 500ms)
      let currentTime = now()
      let timeDiff = currentTime - lastAnimationUpdate
      let timeDiffMs = timeDiff.inMilliseconds

      if timeDiffMs >= 1350 and currentStatus(state) == StatusPlaying:
        # Update the animation only if the player is playing
        updateAnimationOnly(currentStatusEmoji(currentStatus(state)), state.currentSong)
        lastAnimationUpdate = currentTime  # Update the last animation time

      # Periodic checks
      if counter >= CheckIdleInterval:
        if ctx.isIdle():
          handlePlayerError("Player core idle", ctx)
          break

        if event.eventID in {IDEndFile, IDShutdown}:
          if config.stationUrl.isValidPlaylistUrl():
            if playlistFirstPass:
              handlePlayerError("End of playlist reached", ctx)
              break
            playlistFirstPass = true
          else:
            handlePlayerError("Stream ended", ctx)
            break
        counter = 0
      inc counter

      # Handle user input
      case getKeyWithTimeout(KeyTimeout):
        of Key.P:
          state.isPaused = not state.isPaused
          ctx.pause(state.isPaused)
          # Update the full UI when the player is paused/unpaused
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.M:
          state.isMuted = not state.isMuted
          ctx.mute(state.isMuted)
          # Update the full UI when the player is muted/unmuted
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.Slash, Key.Plus:
          state.volume = min(state.volume + VolumeStep, MaxVolume)
          cE ctx.setProperty("volume", fmtInt64, addr state.volume)
          # Update the full UI when the volume changes
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.Asterisk, Key.Minus:
          state.volume = max(state.volume - VolumeStep, MinVolume)
          cE ctx.setProperty("volume", fmtInt64, addr state.volume)
          # Update the full UI when the volume changes
          updatePlayerUI(state.currentSong, currentStatusEmoji(currentStatus(state)), state.volume)

        of Key.R:
          if not state.isPaused:
            ctx.terminateDestroy()
          illwillDeinit()
          break

        of Key.Q:
          illwillDeinit()
          exit(ctx, state.isPaused)

        of Key.None:
          continue

        else:
          showInvalidChoice()

  except Exception:
    let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
    warn("An error occurred during playback. Edit the station list in: " & fileHint & ".json")
    return

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
  try:
    let data = parseJArray(jsonPath)
    result = (names: @[], urls: @[])

    for i in 0 .. data.high:
      if i mod 2 == 0:
        result.names.add(data[i])
      else:
        let url = if data[i].startsWith("http://") or data[i].startsWith("https://"):
          data[i]
        else:
          "http://" & data[i]
        result.urls.add(url)

  except Exception as e:
    raise newException(MenuError, "Failed to load station list: " & e.msg)

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

proc getFooterOptions*(isMainMenu, isPlayerUI: bool): string =
  ## Returns the footer options based on the context (main menu or submenu).
  echo "DEBUG: getFooterOptions - isMainMenu = ", isMainMenu, ", isPlayerUI = ", isPlayerUI  # Debug log
  result =
    if isMainMenu: "[Q] Quit   [N] Notes   [U] Help"
    elif isPlayerUI: "[Q] Quit   [R] Return   [P] Pause/Play [-/+] Adjust Volume"
    else: "[Q] Quit   [R] Return   [U] Help"

proc handleMenu*(
  section: string,
  items: seq[string],
  paths: seq[string],
  isMainMenu: bool = false,
  baseDir: string = getAppDir() / "assets"
) =
  ## Handles a generic menu for station selection or main category selection.
  ## Supports both directories and JSON files.
  echo "DEBUG: handleMenu - isMainMenu = ", isMainMenu  # Debug log
  while true:
    var returnToParent = false
    clear()
    drawHeader()
    
    # Display the menu
    drawMenu(section, items, isMainMenu = isMainMenu)
    hideCursor()

    while true:
      try:
        let key = getch()
        case key
        of '1'..'9':
          let idx = ord(key) - ord('1')
          if idx >= 0 and idx < items.len:
            if dirExists(paths[idx]):
              # Handle directories (subcategories or station lists)
              var subItems: seq[string] = @[]
              var subPaths: seq[string] = @[]
              for file in walkFiles(paths[idx] / "*.json"):
                let name = file.extractFilename.changeFileExt("").capitalizeAscii
                subItems.add(name)
                subPaths.add(file)
              if subItems.len == 0:
                warn("No station lists available in this category.")
              else:
                # Navigate to subcategories with isMainMenu = false
                handleMenu(items[idx], subItems, subPaths, isMainMenu = false, baseDir = baseDir)
            elif fileExists(paths[idx]) and paths[idx].endsWith(".json"):
              # Handle JSON files (station lists)
              let stations = loadStationList(paths[idx])
              if stations.names.len == 0 or stations.urls.len == 0:
                warn("No stations available. Please check the station list.")
              else:
                # Navigate to station list with isMainMenu = false
                handleMenu(items[idx], stations.names, stations.urls, isMainMenu = false, baseDir = baseDir)
            else:
              # Treat as a station URL and play directly
              let config = MenuConfig(
                currentSection: section,
                currentSubsection: "",
                stationName: items[idx],
                stationUrl: paths[idx]
              )
              playStation(config)
            break
          else:
            showInvalidChoice()

        of 'A'..'L', 'a'..'l':
          let idx = ord(toLowerAscii(key)) - ord('a') + 9
          if idx >= 0 and idx < items.len:
            if dirExists(paths[idx]):
              # Handle directories (subcategories or station lists)
              var
                subItems: seq[string] = @[]
                subPaths: seq[string] = @[]
              for file in walkFiles(paths[idx] / "*.json"):
                let name = file.extractFilename.changeFileExt("").capitalizeAscii
                subItems.add(name)
                subPaths.add(file)
              if subItems.len == 0:
                warn("No station lists available in this category.")
              else:
                # Navigate to subcategories with isMainMenu = false
                handleMenu(items[idx], subItems, subPaths, isMainMenu = false, baseDir = baseDir)
            elif fileExists(paths[idx]) and paths[idx].endsWith(".json"):
              # Handle JSON files (station lists)
              let stations = loadStationList(paths[idx])
              if stations.names.len == 0 or stations.urls.len == 0:
                warn("No stations available. Please check the station list.")
              else:
                # Navigate to station list with isMainMenu = false
                handleMenu(items[idx], stations.names, stations.urls, isMainMenu = false, baseDir = baseDir)
            else:
              # Treat as a station URL and play directly
              let config = MenuConfig(
                currentSection: section,
                currentSubsection: "",
                stationName: items[idx],
                stationUrl: paths[idx]
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
  handleMenu("Main", categories.names, categories.paths, isMainMenu = true, baseDir = baseDir)

export hideCursor, error

when isMainModule:
  try:
    drawMainMenu()
  except MenuError as e:
    error("Menu error: " & e.msg)