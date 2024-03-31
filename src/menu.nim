import
  terminal, os, ui, strutils,
  client, net, player, link

proc call(sub: string; sect = ""; stat, link: string) =
  if link == "": warn "link empty"
  elif link.contains " ": warn "link dont exist or is invalid"
  else:
    clear()
    if sect == "": say (("PNimRP > " & sub) & (" > " & stat))
    else: say (("PNimRP > " & sub) & (" > " & sect) & (
        " > " & stat))
    sayTermDraw12()

    if not doesLinkWork link:
      warn "no link work"
      return
    var ctx = create()
    ctx.init link
    var
      #echoPlay = true
      event = ctx.waitEvent
      isPaused = false
      isMuted = false
    let currentSong = getCurrentSong link
      #nowPlayingExcept = false
    #echo "link in call() before while true: " & link

    while true:
      if not isPaused: event = ctx.waitEvent
      setCursorPos 0, 2
      eraseLine()
      echo "event state: ", eventName event.eventID

      if event.eventID in [IDEndFile, IDShutdown]:
        warn "end of file? bad link?"
        terminateDestroy ctx
        break
      eraseLine()
      if not isPaused:
        if not isMuted: say "Playing", fgGreen
        else: warn "Muted"
      else:
        if not isMuted: warn "Paused"
        else: warn "paused and muted"
      #if isMuted: warn "Muted", 4
        #if echoPlay:
      #var event = ctx.waitEvent 1000

      if currentSong != "notimplemented":
        say "Now Streaming: " & getCurrentSong link, fgGreen
      cursorUp()
      #  echoPlay = false

      #remove cursorUp?
      #add time check playing error link
      #if not isPaused:
        #var t0 = now().second
        #event = ctx.waitEvent 1000
        #if now().second - t0 >= 5:
          # error "timeout of 5s"

      case getch():
        of 'u', 'U':
          #lyrics update func -> just to restart while true

          #[cursorDown()
          sayPos 4, "Updated"

          eraseLine()
          cursorUp()]#
          discard
        of 'p', 'P':
          if isPaused:
            #if nowPlayingExcept != true:
            #cursorUp()
            eraseLine()
            #cursorDown()
            #eraseLine()
            #if nowPlayingExcept != true:
            #cursorUp()

            isPaused = false
            ctx.pause false
            #echoPlay = true
          else:
            eraseLine()
            #warn "Paused", 4
            cursorUp()

            ctx.pause true
            isPaused = true

        of 'm', 'M':
          if isMuted:
            #if nowPlayingExcept != true:
            #[cursorUp()
            eraseLine()
            cursorDown()
            eraseLine()
            #if nowPlayingExcept != true:
            cursorUp()]#

            ctx.mute false
            #echoPlay = true
            isMuted = false

          else:
            eraseLine()
            #warn "Muted", 4
            cursorUp()
            ctx.mute true
            isMuted = true

        of '/', '+':
          let volumeIncreased = ctx.volume true

        #[var metadata: NodeList
          echo "getPropreturnVal:", ctx.getProperty("metadata", fmtNodeMap, addr metadata)
          echo "metadata", metadata.num
          for i in 0 .. 100:
            try:echo "metadatavalues", metadata.values[i]
            except:discard]#
          cursorDown()
          warn "Volume+: " & $volumeIncreased
          cursorUp()
          eraseLine()
          cursorUp()

        of '*', '-':
          let volumeDecreased = ctx.volume false

          cursorDown()
          warn "Volume-: " & $volumeDecreased
          cursorUp()
          eraseLine()
          cursorUp()

        of 'r', 'R':
          if not isPaused: terminateDestroy ctx
          break
        of 'q', 'Q': exit ctx, isPaused
        else: inv()

proc initJsonLists(sub, file: string; sect = ""): seq[seq[string]] =
  var n, l: seq[string] = @[]
  let input = parseJArray file

  for f in input.low .. input.high:
    case f mod 2:
      of 0: n.add input[f]
      of 1:
        if input[f].startsWith("http://") or
          input[f].startsWith "https://":
          l.add input[f]
        else: l.add "http://" & input[f]
      else: discard
  @[n, l]

proc initIndx*(dir = "assets"): seq[seq[string]] =
  var files, names: seq[string]

  for file in walkFiles(dir & "/*"):
    if dir == "assets":
      if file != "assets/qoute.json":
        files.add file
    else: files.add file
    var procFile = file
    procFile.removePrefix(dir & "/")
    procFile[0] = procFile[0].toUpperAscii
    procFile.removeSuffix ".json"
    if dir == "assets":
      if procFile != "Qoute":
        names.add procFile
    else: names.add procFile

  #TODO add directory parse support
  for directory in walkDirs(dir & "/*"):
    var procDir = directory
    procDir.removePrefix(dir & "/")
    procDir = procDir & "/"
    files.add procDir
    names.add procDir

  if dir == "assets": names.add "Notes"
  @[names, files]

proc drawMainMenu*(dir = "assets")

proc menu(sub, file: string; sect = "") =
  if sub.endsWith "/":
    drawMainMenu("assets/" & sub)
    return
    #echo sub
  let
    list = initJsonLists(sub, file, sect)
    n = list[0]
    l = list[1]

  while true:
    var returnBack = false
    drawMenu sub, n, sect
    #echo l
    #add conditiinal check for every if len not thereown size
    #else no use danger use release
    while true:
      try:
        case getch():
          of '1': call sub, sect, n[0], l[0]; break
          of '2': call sub, sect, n[1], l[1]; break
          of '3': call sub, sect, n[2], l[2]; break
          of '4': call sub, sect, n[3], l[3]; break
          of '5': call sub, sect, n[4], l[4]; break
          of '6': call sub, sect, n[5], l[5]; break
          of '7': call sub, sect, n[6], l[6]; break
          of '8': call sub, sect, n[7], l[7]; break
          of '9': call sub, sect, n[8], l[8]; break
          of 'A', 'a': call sub, sect, n[9], l[9]; break
          of 'B', 'b': call sub, sect, n[10], l[10]; break
          of 'C', 'c': call sub, sect, n[11], l[11]; break
          of 'D', 'd': call sub, sect, n[12], l[12]; break
          of 'E', 'e': call sub, sect, n[13], l[13]; break
          of 'F', 'f': call sub, sect, n[14], l[14]; break
          of 'R', 'r':
            returnBack = true
            #writeStackTrace()
            break
          of 'Q', 'q': exitEcho()
          else: inv()
      except IndexDefect: inv()
    if returnBack: break

proc drawMainMenu*(dir = "assets") =
  let
    indx = initIndx dir
    names = indx[0]
    files = indx[1]
  #TODO menu dynamic selection; only 15 items possible!
  while true:
    var returnBack = false
    clear()
    #echo names
    #echo files
    #echo dirs
    #add drawMenu
    sayTermDraw8()
    say "Station Categories:", fgGreen
    sayIter names, ret = if dir != "assets": true else: false
    try:
      while true:
        #var getch = getch()
        case getch():
          of '1': menu names[0], files[0]; break
          of '2': menu names[1], files[1]; break
          of '3': menu names[2], files[2]; break
          of '4': menu names[3], files[3]; break
          of '5': menu names[4], files[4]; break
          of '6': menu names[5], files[5]; break
          of '7': menu names[6], files[6]; break
          of '8': menu names[7], files[7]; break
          of '9': menu names[8], files[8]; break
          of 'A', 'a': menu names[9], files[9]; break
          of 'B', 'b': menu names[10], files[10]; break
          of 'C', 'c': menu names[11], files[11]; break
          of 'D', 'd': menu names[12], files[12]; break
          of 'E', 'e': menu names[13], files[13]; break
          of 'F', 'f': menu names[14], files[14]; break
          of 'G', 'g': menu names[15], files[15]; break
          of 'H', 'h': menu names[16], files[16]; break
          of 'I', 'i': menu names[17], files[17]; break
          of 'J', 'j': menu names[18], files[18]; break
          of 'K', 'k': menu names[19], files[19]; break
          of 'N', 'n': notes(); break
          of 'R', 'r':
            if dir != "assets":
              returnBack = true
              break
            else: inv()
          of 'q', 'Q': exitEcho()
          else:
            #echo getch
            inv()
    except IndexDefect:
      #warn "indexdefect"
      inv()

    if returnBack: break
