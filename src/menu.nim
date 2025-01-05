import
  terminal, os, ui, strutils,
  client, net, player, link, illwill

type
  MenuError* = object of CatchableError
  PlayerState = object
    isPaused: bool
    isMuted: bool
    currentSong: string
    volume: int
  
  MenuConfig = object
    ctx: ptr Handle
    currentSection: string
    currentSubsection: string
    stationName: string
    stationUrl: string

const
  CheckIdleInterval = 25  # Check idle state every N iterations
  KeyTimeout = 25        # Milliseconds to wait for key input
  ValidMenuKeys = {'1'..'9', 'A'..'K', 'N', 'R', 'Q'}

proc updateNowPlaying(state: var PlayerState, ctx: ptr Handle) =
  ## Updates the now playing display
  state.currentSong = ctx.getCurrentMediaTitle()  # Updated function name
  eraseLine()
  say("Now Streaming: " & state.currentSong, fgGreen)
  cursorUp()

proc handlePlayerError(msg: string, ctx: ptr Handle = nil, shouldReturn = false) =
  ## Handles player errors consistently
  warn(msg)
  if ctx != nil:
    ctx.terminateDestroy()
  if shouldReturn:
    return
type
  PlayerStatus = enum
    StatusPlaying
    StatusMuted
    StatusPaused
    StatusPausedMuted

proc updatePlayerState(state: var PlayerState, ctx: ptr Handle) =
  ## Updates and displays the player state
  cursorDown()
  eraseLine()

  # Determine the current status based on the player state
  let currentStatus =
    if not state.isPaused and not state.isMuted:
      StatusPlaying
    elif not state.isPaused and state.isMuted:
      StatusMuted
    elif state.isPaused and not state.isMuted:
      StatusPaused
    else:  # isPaused and isMuted
      StatusPausedMuted

  # Define the state message and color based on the current status
  let stateMsg = case currentStatus
    of StatusPlaying: ("Playing", fgGreen)
    of StatusMuted: ("Muted", fgRed)
    of StatusPaused: ("Paused", fgYellow)
    of StatusPausedMuted: ("Paused and Muted", fgRed)

  # Display the state message
  say(stateMsg[0], stateMsg[1])
  setCursorPos(0, 2)

proc handleVolumeChange(ctx: ptr Handle, increase: bool) =
  ## Handles volume changes and notifications
  let newVolume = ctx.adjustVolume(increase)  # Updated function name
  let volumeMsg = (if increase: "Volume+: " else: "Volume-: ") & $newVolume
  showInvalidChoice(volumeMsg)
  setCursorPos(0, 2)

proc isValidPlaylistUrl(url: string): bool =
  ## Checks if URL points to a valid playlist format
  result = url.endsWith(".pls") or url.endsWith(".m3u")

proc playStation(config: MenuConfig) {.raises: [MenuError].} =
  ## Plays a radio station and handles user input
  try:
    if config.stationUrl == "":
      raise newException(MenuError, "Empty station URL")
    elif " " in config.stationUrl:
      raise newException(MenuError, "Invalid station URL")
    
    # Using isValid field from LinkValidationResult
    if not validateLink(config.stationUrl).isValid:
      raise newException(MenuError, "Station URL not accessible")

    var
      ctx = create()
      state = PlayerState(isPaused: false, isMuted: false)
      isObserving = false
      counter: uint8
      playlistFirstPass = false
    
    ctx.init(config.stationUrl)
    var event = ctx.waitEvent()
    
    try:
      illwillInit(false)
    except:
      discard  # Non-critical failure
    
    cursorDown()
    say("Playing", fgGreen)
    cursorDown()
    setCursorPos(0, 2)
    
    while true:
      if not state.isPaused:
        event = ctx.waitEvent()
      
      # Handle playback events
      if event.eventID in {IDPlaybackRestart} and not isObserving:
        ctx.observeMediaTitle()  # Updated function name
        isObserving = true
      
      if event.eventID in {IDEventPropertyChange}:
        updateNowPlaying(state, ctx)
      
      # Periodic checks
      if counter >= CheckIdleInterval:
        if ctx.isIdle():  # Updated function name
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
          updatePlayerState(state, ctx)
        
        of Key.M:
          state.isMuted = not state.isMuted
          ctx.mute(state.isMuted)
          updatePlayerState(state, ctx)
        
        of Key.Slash, Key.Plus:
          handleVolumeChange(ctx, true)
        
        of Key.Asterisk, Key.Minus:
          handleVolumeChange(ctx, false)
        
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
    
  except Exception as e:
    raise newException(MenuError, "Playback error: " & e.msg)

# Rest of the code remains unchanged as it doesn't interact with the player functions
proc loadStationList(jsonPath: string): tuple[names, urls: seq[string]] =
  ## Loads station names and URLs from JSON file
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
  ## Loads available station categories
  result = (names: @[], paths: @[])
  let nativePath = baseDir / "*".unixToNativePath
  
  for file in walkFiles(nativePath):
    if baseDir == getAppDir() / "assets" and file.endsWith("quote.json"):
      continue
      
    let name = file.extractFilename.changeFileExt("")
    if name != "quote":
      result.names.add(name.capitalizeAscii)
      result.paths.add(file)
  
  for dir in walkDirs(nativePath):
    let name = dir.extractFilename & DirSep
    result.names.add(name)
    result.paths.add(dir)
  
  if baseDir == getAppDir() / "assets":
    result.names.add("Notes")


proc handleStationMenu*(section, jsonPath, subsection = "") {.raises: [MenuError].} =
  ## Handles the station selection menu
  if section.endsWith(DirSep):
    drawMenu("Main", @[], section)
    return
  
  # Load station list
  let stations = loadStationList(jsonPath)
  
  # Check for empty station list
  if stations.names.len == 0 or stations.urls.len == 0:
    warn("No stations available. Please check the station list.")
    return
  
  while true:
    var returnToMain = false
    drawMenu(section, stations.names, subsection)
    hideCursor()
    
    while true:
      try:
        let key = getch()
        case key
        of '1'..'9':
          let idx = ord(key) - ord('1')
          if idx >= 0 and idx < stations.names.len:
            let config = MenuConfig(
              currentSection: section,
              currentSubsection: subsection,
              stationName: stations.names[idx],
              stationUrl: stations.urls[idx]
            )
            playStation(config)
            break
          else:
            showInvalidChoice()
        
        of 'A'..'K':
          let idx = ord(key) - ord('A') + 9
          if idx >= 0 and idx < stations.names.len:
            let config = MenuConfig(
              currentSection: section,
              currentSubsection: subsection,
              stationName: stations.names[idx],
              stationUrl: stations.urls[idx]
            )
            playStation(config)
            break
          else:
            showInvalidChoice()
        
        of 'R', 'r':
          returnToMain = true
          break
        
        of 'Q', 'q':
          exit(ctx, false)
          break
        
        else:
          showInvalidChoice()
      
      except IndexDefect:
        showInvalidChoice()
    
    if returnToMain:
      break

proc drawMainMenu*(baseDir = getAppDir() / "assets") =
  ## Draws and handles the main category menu
  let categories = loadCategories(baseDir)
  
  while true:
    var returnToParent = false
    clear()
    say("Station Categories:", fgGreen)  # Updated: Replaced sayTermDraw12 with say
    for name in categories.names:  # Updated: Replaced sayIter with a loop
      say(name, fgBlue)
    
    try:
      while true:
        let key = getch()
        case key
        of '1'..'9':
          let idx = ord(key) - ord('1')
          if idx < categories.names.len:
            handleStationMenu(categories.names[idx], categories.paths[idx])
            break
        
        of 'A'..'K':
          let idx = ord(key) - ord('A') + 9
          if idx < categories.names.len:
            handleStationMenu(categories.names[idx], categories.paths[idx])
            break
        
        of 'N', 'n':
          showNotes()
          break
        
        of 'R', 'r':
          if baseDir != getAppDir() / "assets":
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

export hideCursor, error

when isMainModule:
  try:
    drawMainMenu()
  except MenuError as e:
    error("Menu error: " & e.msg)
