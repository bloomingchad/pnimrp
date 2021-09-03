proc comedy181() =
  var sect:string = "Comedy"
  var f = readFile("pnimrp.d/181FM/comedy181.csv").split('\n')
  proc s() =
    back(17)
    echo "PNimRP -> ",sect
    echo ""
    echo "Stations Playing ",sect," Music:"
    echo "1 ", f[0]
    echo "2 ", f[1]
    echo "3 ", f[2]
    echo "R Return"
    echo "Q Quit"
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
