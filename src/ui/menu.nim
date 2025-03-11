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
  ],

  playerui

when not defined(simple):
  import asyncdispatch,

    ../audio/metadata,
    ../ui/[
      stationstatus,
      scroll,
      animation,
     ],
    ../json/[
        statuscache
    ]


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

proc chooseForMeOrChooseYourself(itemsLen: int): Key =
  if chooseForMe:
    chooseForMe = false  # Reset the flag after use

    var rndIdx = rand(itemsLen - 1)  # Generate random index within bounds
    while rndIdx == lastStationIdx and itemsLen > 1:  # Ensure it doesn't pick the last station again
      rndIdx = rand(itemsLen - 1)
    lastStationIdx = rndIdx  # Update the last station index

    # Convert the random index to a menu key (1-9, A-M)
    if rndIdx < 9:
      result = Key(ord(Key.One) + rndIdx)
    else:
      result = Key(ord(Key.A) + rndIdx - 9)
  else:
    return getKeyWithTimeout(int32.high)

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

    when not defined(simple):
      if isHandlingJSON(handleMenuIsHandling):
        var stations = newSeqOfCap[StationStatus](32)
        for i in 0..<items.len:
          stations.add(
            StationStatus(
              sectionName: section,
              name:     items[i],
              coord:    emojiPositions[i],  # From ui.nim
              url:      paths[i],             # Station URL
              status:   lsChecking         # Initial state
            )
          )

        hookCacheResolveAndDisplay(stations)

    while true:
      try:
        let key = chooseForMeOrChooseYourself(items.len)
        case key
        of Key.One, Key.Two, Key.Three, Key.Four, Key.Five, Key.Six, Key.Seven, Key.Eight, Key.Nine,
         Key.A , Key.B , Key.C , Key.D , Key.E , Key.F , Key.G , Key.H , Key.I ,Key.J , Key.K , Key.L ,Key.M:
          let idx = 
            if char(int(key)) in {'1'..'9'}:
              ord(char(int(key))) - ord('1')
            else: ord(toLowerAscii(chr(int(key)))) - ord('a') + 9
          
          if idx >= 0 and idx < items.len:
            let selectedPath = paths[idx]
            if dirExists(selectedPath):
              # Handle directories (subcategories or station lists)
              var subItems, subPaths = newSeqOfCap[string](32)

              let result = loadCategories(selectedPath)
              for nameOffolder in result[0]:
                subItems.add(nameOffolder)
              for folderPath in result[1]:
                subPaths.add(folderPath)
              if subItems.len == 0:
                warn("No station lists available in this category.")
              else:
                # Navigate to subcategories with isMainMenu = false
                handleMenu(items[idx], subItems, subPaths, isMainMenu = false, baseDir = baseDir, handleMenuIsHandling = hmIsHandlingDirectory)
                handleMenu(items[idx], subItems, subPaths, isMainMenu = false, baseDir = selectedPath, handleMenuIsHandling = hmIsHandlingDirectory)
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

        of Key.N:
          if isMainMenu:  # Only allow Notes in the main menu
            showNotes()
            break
          else:
            showInvalidChoice()

        of Key.U:
          showHelp()
          break

        of Key.R:
          if not isMainMenu or baseDir != getAppDir() / "assets":
            returnToParent = true
            break
          else:
            showInvalidChoice()
        of Key.S:
          chooseForMe = true

        of Key.Q:
          showExitMessage()
          break

        else:
          showInvalidChoice()

      except IndexDefect:
        warn "IndexDefect, did you fill too much stations?"
        break

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
