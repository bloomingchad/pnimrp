proc comedy181() =
  var sect:string = "Comedy"
  var f = readFile("pnimrp.d/181FM/comedy181.csv").splitLines()
  proc s() =
    mnuCls()
    mnuSy 2,1,fgYellow,fmt"PNimRP -> {sub} -> {sect}"
    mnuSyIter 2,4,fgGreen,fmt"{sect} Station Playing Music:"
    mnuSyIter 6,5,fgBlue,fmt"""1 {f[0]}
2 {f[1]}
3 {f[2]}
R Return
Q Exit"""
    tb.display()
  proc r() =
    while true:
      sleep 160
      case getKey():
        of Key.None: discard
        of Key.One:
          call(sub,sect,f[0],f[3])
          s() ; r()
        of Key.Two:
          call(sub,sect,f[1],f[4])
          s() ; r()
        of Key.Three:
          call(sub,sect,f[2],f[5])
          s() ; r()
        of Key.R: fm181()
        of Key.Escape , Key.Q: exitEcho() ;exitProc()
        else:
          inv()
          r()
    tb.display()
    sleep(20)
  s() ; r()
