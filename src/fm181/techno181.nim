from os import sleep
import terminal,../base
from strformat import fmt

proc techno181* =
 const sub = "181FM"
 const sect = "Techno"
 var f = parse "181FM/techno181.csv"
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {f[0]}
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
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,f[0],f[10] ; break
    of '2': call sub,sect,f[1],f[11] ; break
    of '3': call sub,sect,f[2],f[12] ; break
    of '4': call sub,sect,f[3],f[13] ; break
    of '5': call sub,sect,f[4],f[14] ; break
    of '6': call sub,sect,f[5],f[15] ; break
    of '7': call sub,sect,f[6],f[16] ; break
    of '8': call sub,sect,f[7],f[17] ; break
    of '9': call sub,sect,f[8],f[18] ; break
    of 'A','a': call sub,sect,f[9],f[19] ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
