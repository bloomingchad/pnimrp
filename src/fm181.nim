import terminal, term

proc fm181* =
 const sub = "FM181"
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
   case getch():
    of '1': menu sub,"fm181/eight181","80s"; break
    of '2': menu sub,"fm181/nine181","90s"; break
    of '3': menu sub,"fm181/comedy181","Comedy"; break
    of '4': menu sub,"fm181/country181","Country"; break
    of '5': menu sub,"fm181/easy181","Easy Listening"; break
    of '6': menu sub,"fm181/latin181","Latin"; break
    of '7': menu sub,"fm181/oldies181","Oldies"; break
    of '8': menu sub,"fm181/pop181","Pop"; break
    of '9': menu sub,"fm181/rock181","Rock"; break
    of 'A','a': menu sub,"fm181/techno181","Techno"; break
    of 'B','b': menu sub,"fm181/urban181","Urban"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
