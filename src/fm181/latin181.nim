proc latin181() =
  var sect:string = "Latin"
  var f = readFile("pnimrp.d/181FM/latin181.csv").split('\n')
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
    var play:char = read()
    case play:
      of '1':
        call(sub,sect,f[0],f[3])
        s() ; r()
      of '2':
        call(sub,sect,f[1],f[4])
        s() ; r()
      of '3':
        call(sub,sect,f[2],f[5])
        s() ; r()
      of 'R','r': fm181()
      of 'Q','q': exitEcho()
      else:
        inv()
        back(4)
        r()
  s() ; r()
