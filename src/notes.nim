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
  sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
  sayIter """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
  while true:
   sleep 100
   case getch():
    of 'T','t':
     when defined windows: exec "notepad.exe",["TERMS"],1 ; exitEcho()
     when defined posix:
      warn "type :q and enter to exit"
      say "Please wait..."
      sleep 750
      showCursor()
      exec "vi",["TERMS"],1
      hideCursor()
      break
    of 'r','R': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
