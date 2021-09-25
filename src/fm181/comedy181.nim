from os import sleep
from terminal import getch
import ../base

proc comedy181* =
 const sub = "181FM"
 const sect = "Comedy"
 var f = parse "181FM/comedy181.csv"
 while true:
  var j = false
  drawMenuSect sub,sect,"1 " & f[0]
  sayC "2 " & f[1]
  sayC "3 " & f[2]
  sayIter """R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,f[0],f[3] ; break
    of '2': call sub,sect,f[1],f[4] ; break
    of '3': call sub,sect,f[2],f[5] ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
