import terminal

func getFooterOptions*(isMainMenu, isPlayerUI: bool): string =
  ## Returns footer options string based on context (main menu/submenu/player).
  result =
    if isMainMenu:
      "[Q] Quit | [N] Notes | [U] Help | [S] ImFeelingLucky"
    elif isPlayerUI:
      "[Q] Quit | [R] Return | [P] Pause/Play | [-/+] Vol | [L] Like"
    else:
      "[Q] Quit | [R] Return | [U] Help | [S] ImFeelingLucky"

proc volumeColor*(volume: int): ForegroundColor =
  if volume > 110: fgRed
  elif volume < 60: fgBlue
  else:
    fgGreen
