proc easy181() =
 var sect:string = "Easy Listening"
 var f = parse "181FM/easy181.csv"
 proc s() =
  mnuCls 0
  mnuSy 2,1,fgYellow,fmt"PNimRP > {sub} > {sect}"
  mnuSyIter 2,4,fgGreen,fmt"{sect} Station Playing Music:"
  mnuSyIter 6,5,fgBlue,fmt"""1 {f[0]}
2 {f[1]}
3 {f[2]}
4 {f[3]}
5 {f[4]}
6 {f[5]}
7 {f[6]}
8 {f[7]}
9 {f[8]}
A {f[9]}
B {f[10]}
C {f[11]}
D {f[12]}
E {f[13]}
F {f[14]}
R Return
Q Exit"""
 proc r() =
  while true:
   sleep 70
   case getKey():
   of Key.None: discard
   of Key.One:
    call(sub,sect,f[0],f[15])
    s() ; r()
   of Key.Two:
    call(sub,sect,f[1],f[16])
    s() ; r()
   of Key.Three:
    call(sub,sect,f[2],f[17])
    s() ; r()
   of Key.Four:
    call(sub,sect,f[3],f[18])
    s() ; r()
   of Key.Five:
    call(sub,sect,f[4],f[19])
    s() ; r()
   of Key.Six:
    call(sub,sect,f[5],f[20])
    s() ; r()
   of Key.Seven:
    call(sub,sect,f[6],f[21])
    s() ; r()
   of Key.Eight:
    call(sub,sect,f[7],f[22])
    s() ; r()
   of Key.Nine:
    call(sub,sect,f[8],f[23])
    s() ; r()
   of Key.A:
    call(sub,sect,f[9],f[24])
    s() ; r()
   of Key.B:
    call(sub,sect,f[10],f[25])
    s() ; r()
   of Key.C:
    call(sub,sect,f[11],f[26])
    s() ; r()
   of Key.D:
    call(sub,sect,f[12],f[27])
    s() ; r()
   of Key.E:
    call(sub,sect,f[13],f[28])
    s() ; r()
   of Key.F:
    call(sub,sect,f[14],f[29])
    s() ; r()
   of Key.R: fm181()
   of Key.Q,Key.Escape: exitProc() ;exitEcho()
   else:
    inv()
    r()
 s() ; r()
