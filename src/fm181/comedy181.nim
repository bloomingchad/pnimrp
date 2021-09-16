proc comedy181() =
 const sect = "Comedy"
 var f = parse "181FM/comedy181.csv"
 proc s() =
  clsIter 0
  say 2,1,fgYellow,fmt"PNimRP > {sub} > {sect}"
  sayIter 2,4,fgGreen,fmt"{sect} Station Playing Music:"
  sayIter 6,5,fgBlue,fmt"""1 {f[0]}
2 {f[1]}
3 {f[2]}
R Return
Q Exit"""
 proc r() =
  while true:
   sleep 70
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
    of Key.Escape , Key.Q: exitProc();exitEcho()
    else:
     inv()
     r()
 s() ; r()
