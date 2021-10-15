import base/[termbase, playerbase]
from os import sleep
from terminal import getch,terminalWidth,showCursor,hideCursor
from strutils import repeat
from strformat import fmt

proc notes* =
 while true:
  var j = false
  const sub = "Notes"
  clear()
  say fmt"PNimRP > {sub}"
  sayPos 0, ('-'.repeat int terminalWidth() / 8) & ('>'.repeat int terminalWidth() / 12)
  sayIter """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
  while true:
   sleep 100
   case getch():
    of 'T','t':
     when defined windows: exec "notepad.exe",["TERMS"], stream = true; break
     when defined posix:
      when defined android:
       showCursor()
       exec "editor",["TERMS"], stream = true
       hideCursor()
       break
      else:
       warn "type esc, :q and enter to exit"
       say "Please wait..."
       sleep 750
       showCursor()
       exec "vi",["TERMS"], stream = true
     else: showCursor(); echo "please open TERMS file"; quit QuitSuccess
    of 'r','R': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
