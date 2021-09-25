from os import sleep
from terminal import getch
import ../base

proc easy181* =
 const sub = "181FM"
 const sect = "Easy Listening"
 var f = parse "181FM/easy181.csv"
 while true:
  var j = false
  drawMenuSect sub,sect,"1 " & f[0]
  sayC "2 " & f[1]
  sayC "3 " & f[2]
  sayC "4 " & f[3]
  sayC "5 " & f[4]
  sayC "6 " & f[5]
  sayC "7 " & f[6]
  sayC "8 " & f[7]
  sayC "9 " & f[8]
  sayC "A " & f[9]
  sayC "B " & f[10]
  sayC "C " & f[11]
  sayC "D " & f[12]
  sayC "E " & f[13]
  sayC "F " & f[14]
  sayC """R Return
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
    of 'b','B': call sub,sect,f[10],f[25] ; break
    of 'c','C': call sub,sect,f[11],f[26] ; break
    of 'd','D': call sub,sect,f[12],f[27] ; break
    of 'e','E': call sub,sect,f[13],f[28] ; break
    of 'f','F': call sub,sect,f[14],f[29] ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
