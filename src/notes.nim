proc notes() =
 clear()
 sayIter 5,fgGreen, """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
 while true: 
  sleep 100
  case getch():
   of 'T','t':
    when defined windows: exec "notepad.exe",["COPYING"],1 ; exitProc();exitEcho()
    when defined posix:
     sayIter 13,fgRed,"type :q and enter to exit"
     sayIter 13,fgBlue,"Please wait..."
     sleep 750
     showCursor()
     exec "vi",["TERMS"],1
     hideCursor()
   of 'r','R': break
   of 'Q','q': exitEcho()
   else: inv()
