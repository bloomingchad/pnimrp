proc notes() =
  mnuCls()
  Cls(2)
  mnuSyIter 6,5,fgGreen, """PNimRP Copyright (C) 2021 antonl05
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions. press `t` for details"""
  while true:
    sleep 160
    case getKey():
      of Key.None: discard
      of Key.T:
        when defined windows: discard execCmd("notepad.exe TERMS") ; exitProc()
        when defined posix:
          mnuSyIter 6,13,fgRed,"type :q and enter to exit"
          mnuSy 6,16,fgBlue,"Please wait..."
          sleep 3000
          discard execCmd "vi TERMS"
          exitProc()
      of Key.R:
        mnuCls()
        main()
      of Key.Q: exitProc()
      else: inv()
