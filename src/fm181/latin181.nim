from os import sleep
import terminal,../base
from strformat import fmt

proc latin181* =
 const sub = "181FM"
 var sect = "Latin"
 var f = parse "181FM/latin181.csv"
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {f[0]}
2 {f[1]}
3 {f[2]}
R Return
Q Exit"""
  while true:
   sleep 70
   case getch():
    of '1': call sub,sect,f[0],f[3] ; break
    of '2': call sub,sect,f[1],f[4] ; break
    of '3': call sub,sect,f[2],f[5] ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
