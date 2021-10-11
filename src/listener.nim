from os import sleep
from terminal import getch
import base/[termbase,menu]

proc listener* =
 const sub = "Listener"
 while true:
  clear()
  var j = false
  drawMenu sub,"""1 Section1
2 Section2
3 Section3
4 Section4
R Return
Q Quit"""
  while true:
   sleep 100
   case getch():
    of '1': endMenu15 sub,"Section1","listener/listener1"; break
    of '2': endMenu15 sub,"Section2","listener/listener2"; break
    of '3': endMenu15 sub,"Section3","listener/listener3"; break
    of '4': endMenu5 sub,"Section4","listener/listener4"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
