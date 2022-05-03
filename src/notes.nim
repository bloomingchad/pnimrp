import term, terminal, strutils

proc notes* =
 while true:
  var j = false
  const sub = "Notes"
  clear()
  say "PNimRP > " & sub
  sayPos 0, ('-'.repeat int terminalWidth() / 8) & ('>'.repeat int terminalWidth() / 12)
  sayIter """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
  while true:
   case getch():
    of 'T','t':
     when defined windows: exec "notepad.exe",["LICENSE"], stream = true; break
     when defined posix:
      when defined android:
       showCursor()
       exec "editor",["LICENSE"], stream = true
       hideCursor()
       break
      else:
       warn "type esc, :q and enter to exit"
       showCursor()
       exec "vi",["LICENSE"], stream = true
       hideCursor()
     else:
       showCursor()
       echo "please open LICENSE file"
       quit()
    of 'r','R': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
