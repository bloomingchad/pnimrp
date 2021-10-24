from os import sleep
import terminal
import base/[term,menu]

proc fm181* =
 const sub = "181FM"
 while true:
  clear()
  var j = false
  drawMenu sub,"""1 80s
2 90s
3 Comedy
4 Country
5 Easy
6 Latin
7 Oldies
8 Pop
9 Rock
A Techno
B Urban
R Return
Q Quit"""
  while true:
   sleep 100
   case getch():
    of '1': endMenu5 sub,"fm181/eight181","80s"; break
    of '2': endMenu5 sub,"fm181/nine181","90s"; break
    of '3': endMenu3 sub,"fm181/comedy181","Comedy"; break
    of '4': endMenu10 sub,"fm181/country181","Country"; break
    of '5': endMenu15 sub,"fm181/easy181","Easy Listening"; break
    of '6': endMenu3 sub,"fm181/latin181","Latin"; break
    of '7': endMenu10 sub,"fm181/oldies181","Oldies"; break
    of '8': endMenu10 sub,"fm181/pop181","Pop"; break
    of '9': endMenu10 sub,"fm181/rock181","Rock"; break
    of 'A','a': endMenu10 sub,"fm181/techno181","Techno"; break
    of 'B','b': endMenu10 sub,"fm181/urban181","Urban"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
