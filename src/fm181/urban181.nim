proc urban181() =
  var sect:string = "Urban"
  var f = readFile("pnimrp.d/181FM/urban181.csv").splitLines()
  proc s() =
    back(17)
    echo "PNimRP -> ",sect,"\n"
    echo "Stations Playing ",sect," Music:"
    echo "1 ", f[0]
    echo "2 ", f[1]
    echo "3 ", f[2]
    echo "4 ", f[3]
    echo "5 ", f[4]
    echo "6 ", f[5]
    echo "7 ", f[6]
    echo "8 ", f[7]
    echo "9 ", f[8]
    echo "A ", f[9]
    echo "R Return"
    echo "Z Refresh"
    echo "Q Quit"
  proc r() =
    var play:char = read()
    case play:
      of '1':
        call(sub,sect,f[0],f[10])
        s()
        r()
      of '2':
        call(sub,sect,f[1],f[11])
        s()
        r()
      of '3':
        call(sub,sect,f[2],f[12])
        s()
        r()
      of '4':
        call(sub,sect,f[3],f[13])
        s()
        r()
      of '5':
        call(sub,sect,f[4],f[14])
        s()
        r()
      of '6':
        call(sub,sect,f[5],f[15])
        s()
        r()
      of '7':
        call(sub,sect,f[6],f[16])
        s()
        r()
      of '8':
        call(sub,sect,f[7],f[17])
        s()
        r()
      of '9':
        call(sub,sect,f[8],f[18])
        s()
        r()
      of 'A':
        call(sub,sect,f[9],f[19])
        s()
        r()
      of 'R','r': fm181()
      of 'Z','z': urban181()
      of 'Q','q': exitEcho()
      else:
        inv()
        back(4)
        r()
  s()
  r()
