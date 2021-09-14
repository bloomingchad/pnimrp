proc notes() =
  mnuCls 0
  Cls 2
  mnuSyIter 6,5,fgGreen, """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
  while true:
    sleep 100
    case getKey():
      of Key.None: discard
      of Key.T:
        when defined windows: exec "notepad.exe",["COPYING"],1 ; exitProc();exitEcho()
        when defined posix:
          mnuSyIter 6,13,fgRed,"type :q and enter to exit"
          mnuSy 6,16,fgBlue,"Please wait..."
          sleep 3000
          exec "vi",["TERMS"],1
          exitProc()
          exitEcho()
      of Key.R: mnuCls 0 ; main()
      of Key.Q: exitProc();exitEcho()
      else: inv()
