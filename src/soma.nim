from os import sleep
from terminal import getch
import base/[termbase,menu]

proc soma* =
 const sub = "SomaFM"
 while true:
  clear()
  var j = false
  drawMenu sub,"""1 Section1
2 Section2
3 Section3
R Return
Q Quit"""
  while true:
   sleep 100
   case getch():
    of '1': endMenu15 sub,"Section1","soma/soma1"; break
    of '2': endMenu15 sub,"Section2","soma/soma2"; break
    of '3': endMenu3 sub,"Section2","soma/soma3"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
