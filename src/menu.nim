import
  terminal, os, ui, strutils,
  client, net, player, link, illwill

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

type
  PlayerStatus = enum  # Enumeration for player states
    StatusPlaying
    StatusMuted
    StatusPaused
    StatusPausedMuted

proc currentStatus(state: PlayerState): PlayerStatus =
  if not state.isPaused and not state.isMuted: StatusPlaying
  elif not state.isPaused and state.isMuted: StatusMuted
  elif state.isPaused and not state.isMuted: StatusPaused
  else:                                      StatusPausedMuted

proc isValidPlaylistUrl(url: string): bool =
  ## Checks if the URL points to a valid playlist format (.pls or .m3u).
  result = url.endsWith(".pls") or url.endsWith(".m3u")

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
    
    ctx.init(config.stationUrl)
    var event = ctx.waitEvent()
    
    try:
      illwillInit(false)
    except:
      discard  # Non-critical failure
    
    # Draw the initial player UI
    drawPlayerUI(config.stationName, "Loading...", "Playing", state.volume)
    
    while true:
      if not state.isPaused:
        event = ctx.waitEvent()
      
      # Handle playback events
      if event.eventID in {IDPlaybackRestart} and not isObserving:
        ctx.observeMediaTitle()
        isObserving = true
      
      if event.eventID in {IDEventPropertyChange}:
        state.currentSong = ctx.getCurrentMediaTitle()

        updatePlayerUI(state.currentSong, $currentStatus(state), state.volume)
      
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
          updatePlayerUI(state.currentSong, $currentStatus(state), state.volume)
        
        of Key.M:
          state.isMuted = not state.isMuted
          ctx.mute(state.isMuted)
          updatePlayerUI(state.currentSong, $currentStatus(state), state.volume)
        
        of Key.Slash, Key.Plus:
          state.volume = min(state.volume + VolumeStep, MaxVolume)
          cE ctx.setProperty("volume", fmtInt64, addr state.volume)
          updatePlayerUI(state.currentSong, $currentStatus(state), state.volume)
        
        of Key.Asterisk, Key.Minus:
          state.volume = max(state.volume - VolumeStep, MinVolume)
          cE ctx.setProperty("volume", fmtInt64, addr state.volume)
          updatePlayerUI(state.currentSong, $currentStatus(state), state.volume)
        
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

proc handleMenu*(
  section: string,
  items: seq[string],
  paths: seq[string],
  isMainMenu: bool = false,
  baseDir: string = getAppDir() / "assets"
) =
  ## Handles a generic menu for station selection or main category selection.
  ## Supports both directories and JSON files.
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
                handleMenu(items[idx], subItems, subPaths)
            elif fileExists(paths[idx]) and paths[idx].endsWith(".json"):
              # Handle JSON files (station lists)
              let stations = loadStationList(paths[idx])
              if stations.names.len == 0 or stations.urls.len == 0:
                warn("No stations available. Please check the station list.")
              else:
                # Display a menu for the stations in the JSON file
                handleMenu(items[idx], stations.names, stations.urls)
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
                handleMenu(items[idx], subItems, subPaths)
            elif fileExists(paths[idx]) and paths[idx].endsWith(".json"):
              # Handle JSON files (station lists)
              let stations = loadStationList(paths[idx])
              if stations.names.len == 0 or stations.urls.len == 0:
                warn("No stations available. Please check the station list.")
              else:
                # Display a menu for the stations in the JSON file
                handleMenu(items[idx], stations.names, stations.urls)
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
          if isMainMenu:
            showNotes()
            break
          else:
            showInvalidChoice()

        of 'R', 'r':
          if not isMainMenu or baseDir != getAppDir() / "assets":
            returnToParent = true
            break
          else:
            showInvalidChoice()

        of 'Q', 'q':
          exitEcho()
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
