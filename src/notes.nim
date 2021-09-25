import base
from os import sleep
from terminal import getch,terminalWidth,showCursor,hideCursor
from strutils import repeat

proc notes* =
 const sub = "Notes"
 clear()
 say "PNimRP > " & sub
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
 sayIter """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
 while true: 
  sleep 100
  case getch():
   of 'T','t':
    when defined windows: exec "notepad.exe",["COPYING"],1 ; exitEcho()
    when defined posix:
     warn "type :q and enter to exit"
     say "Please wait..."
     sleep 750
     showCursor()
     exec "vi",["TERMS"],1
     hideCursor()
     back 2
   of 'r','R': break
   of 'Q','q': exitEcho()
   else: inv()
