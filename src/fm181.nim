from os import sleep
import terminal
import base/[termbase,menu]

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
    of '1': endMenu5 sub,"80s","fm181/eight181"; break
    of '2': endMenu5 sub,"90s","fm181/nine181"; break
    of '3': endMenu3 sub,"Comedy","fm181/comedy181"; break
    of '4': endMenu10 sub,"Country","fm181/country181"; break
    of '5': endMenu15 sub,"Easy Listening","fm181/easy181"; break
    of '6': endMenu3 sub,"Latin","fm181/latin181"; break
    of '7': endMenu10 sub,"Oldies","fm181/oldies181"; break
    of '8': endMenu10 sub,"Pop","fm181/pop181"; break
    of '9': endMenu10 sub,"Rock","fm181/rock181"; break
    of 'A','a': endMenu10 sub,"Techno","fm181/techno181"; break
    of 'B','b': endMenu10 sub,"Urban","fm181/urban181"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
