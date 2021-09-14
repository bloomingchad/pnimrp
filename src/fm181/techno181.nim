proc techno181() =
  var sect:string = "Techno"
  var f = parse "181FM/techno181.csv"
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
  echo "Q Quit"
  var play:char = read()
  case play:
    of '1':
      call(sub,sect,f[0],f[10])
      techno181()
    of '2':
      call(sub,sect,f[1],f[11])
      techno181()
    of '3':
      call(sub,sect,f[2],f[12])
      techno181()
    of '4':
      call(sub,sect,f[3],f[13])
      techno181()
    of '5':
      call(sub,sect,f[4],f[14])
      techno181()
    of '6':
      call(sub,sect,f[5],f[15])
      techno181()
    of '7':
      call(sub,sect,f[6],f[16])
      techno181()
    of '8':
      call(sub,sect,f[7],f[17])
      techno181()
    of '9':
      call(sub,sect,f[8],f[18])
      techno181()
    of 'A':
      call(sub,sect,f[9],f[19])
      techno181()
    of 'R','r': fm181()
    of 'Q','q': exitEcho()
    else:
      inv()
      techno181()
