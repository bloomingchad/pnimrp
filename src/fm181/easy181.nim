proc easy181() =
  var sect:string = "Easy Listening"
  back(17)
  var f = readFile("pnimrp.d/181FM/easy181.csv").split('\n')
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
  echo "B ", f[10]
  echo "C ", f[11]
  echo "D ", f[12]
  echo "E ", f[13]
  echo "F ", f[14]
  echo "R Return"
  echo "Q Quit"
  var play:char = read()
  case play:
    of '1':
      call(sub,sect,f[0],f[15])
      easy181()
    of '2':
      call(sub,sect,f[1],f[16])
      easy181()
    of '3':
      call(sub,sect,f[2],f[17])
      easy181()
    of '4':
      call(sub,sect,f[3],f[18])
      easy181()
    of '5':
      call(sub,sect,f[4],f[19])
      easy181()
    of '6':
      call(sub,sect,f[5],f[20])
      easy181()
    of '7':
      call(sub,sect,f[6],f[21])
      easy181()
    of '8':
      call(sub,sect,f[7],f[22])
      easy181()
    of '9':
      call(sub,sect,f[8],f[23])
      easy181()
    of 'A':
      call(sub,sect,f[9],f[24])
      easy181()
    of 'B':
      call(sub,sect,f[10],f[25])
      easy181()
    of 'C':
      call(sub,sect,f[11],f[26])
      easy181()
    of 'D':
      call(sub,sect,f[12],f[27])
      easy181()
    of 'E':
      call(sub,sect,f[13],f[28])
      easy181()
    of 'F':
      call(sub,sect,f[14],f[29])
      easy181()
    of 'R','r': fm181()
    of 'Q','q': exitEcho()
    else:
      inv()
      easy181()
