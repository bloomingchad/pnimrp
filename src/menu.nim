import
  terminal,
  os,
  ui,
  strutils,
  client,
  net,
  player,
  link,
  illwill

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
  state.currentSong = $ctx.getCurrentSongV2()
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

proc updatePlayerState(state: var PlayerState, ctx: ptr Handle) =
  ## Updates and displays the player state
  cursorDown()
  eraseLine()
  
  let stateMsg = case (state.isPaused, state.isMuted)
    of (false, false): ("Playing", fgGreen)
    of (false, true): ("Muted", fgRed)
    of (true, false): ("Paused", fgYellow)
    of (true, true): ("Paused and Muted", fgRed)
  
  say(stateMsg[0], stateMsg[1])
  setCursorPos(0, 2)

proc handleVolumeChange(ctx: ptr Handle, increase: bool) =
  ## Handles volume changes and notifications
  let newVolume = ctx.volume(increase)
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
    elif not doesLinkWork(config.stationUrl):
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
        ctx.seeIfSongTitleChanges()
        isObserving = true
      
      if event.eventID in {IDEventPropertyChange}:
        updateNowPlaying(state, ctx)
      
      # Periodic checks
      if counter >= CheckIdleInterval:
        if bool(ctx.seeIfCoreIsIdling()):
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

proc loadStationList(jsonPath: string): tuple[names, urls: seq[string]] =
  ## Loads station names and URLs from JSON file
  try:
    let data = parseJArray(jsonPath)
    result = (names: @[], urls: @[])
    
    for i in 0 .. data.high:
      if i mod 2 == 0:
        result.names.add(data[i])
      else:
        let url = if data[i].startsWith({"http://", "https://"}):
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
  
  # Load files
  for file in walkFiles(nativePath):
    if baseDir == getAppDir() / "assets" and file.endsWith("quote.json"):
      continue
      
    let name = file.extractFilename.changeFileExt("")
    if name != "quote":
      result.names.add(name.capitalizeAscii)
      result.paths.add(file)
  
  # Load directories
  for dir in walkDirs(nativePath):
    let name = dir.extractFilename & DirSep
    result.names.add(name)
    result.paths.add(dir)
  
  if baseDir == getAppDir() / "assets":
    result.names.add("Notes")

proc handleStationMenu*(section, jsonPath, subsection = "") {.raises: [MenuError].} =
  ## Handles the station selection menu
  if section.endsWith(DirSep):
    drawMainMenu(getAppDir() / "assets" / section)
    return
    
  let stations = loadStationList(jsonPath)
  
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
          if idx < stations.names.len:
            let config = MenuConfig(
              currentSection: section,
              currentSubsection: subsection,
              stationName: stations.names[idx],
              stationUrl: stations.urls[idx]
            )
            playStation(config)
            break
        
        of 'A'..'K':
          let idx = ord(key) - ord('A') + 9
          if idx < stations.names.len:
            let config = MenuConfig(
              currentSection: section,
              currentSubsection: subsection,
              stationName: stations.names[idx],
              stationUrl: stations.urls[idx]
            )
            playStation(config)
            break
        
        of 'R', 'r':
          returnToMain = true
          break
        
        of 'Q', 'q':
          exitEcho()
        
        else:
          showInvalidChoice()
      
      except IndexDefect:
        showInvalidChoice()
    
    if returnToMain:
      break

proc drawMainMenu*(baseDir = getAppDir() / "assets") {.raises: [MenuError].} =
  ## Draws and handles the main category menu
  let categories = loadCategories(baseDir)
  
  while true:
    var returnToParent = false
    clear()
    sayTermDraw8()
    say("Station Categories:", fgGreen)
    sayIter(categories.names, baseDir != getAppDir() / "assets")
    
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
