proc techno181() =
 const sect = "Techno"
 var f = parse "181FM/techno181.csv"
 proc s() =
  clsIter 0
  say 2,1,fgYellow,fmt"PNimRP > {sub} > {sect}"
  say 2,4,fgGreen,fmt"{sect} Station Playing Music:"
  sayIter 6,5,fgBlue,fmt"""1 {f[0]}
2 {f[1]}
3 {f[2]}
4 {f[3]}
5 {f[4]}
6 {f[5]}
7 {f[6]}
8 {f[7]}
9 {f[8]}
A {f[9]}
R Return
Q Exit"""
 proc r() =
  while true:
   sleep 70
   case getKey():
    of Key.None: discard
    of Key.One:
     call(sub,sect,f[0],f[10])
     s() ; r()
    of Key.Two:
     call(sub,sect,f[1],f[11])
     s() ; r()
    of Key.Three:
     call(sub,sect,f[2],f[12])
     s() ; r()
    of Key.Four:
     call(sub,sect,f[3],f[13])
     s() ; r()
    of Key.Five:
     call(sub,sect,f[4],f[14])
     s() ; r()
    of Key.Six:
     call(sub,sect,f[5],f[15])
     s() ; r()
    of Key.Seven:
     call(sub,sect,f[6],f[16])
     s() ; r()
    of Key.Eight:
     call(sub,sect,f[7],f[17])
     s() ; r()
    of Key.Nine:
     call(sub,sect,f[8],f[18])
     s() ; r()
    of Key.A:
     call(sub,sect,f[9],f[19])
     s() ; r()
    of Key.R: fm181()
    of Key.Q, Key.Escape: exitProc();exitEcho()
    else:
     inv()
     r()
 s() ; r()
