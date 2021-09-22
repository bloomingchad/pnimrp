from os import sleep
import terminal,../base
from strformat import fmt
import comedy181,country181,easy181,latin181,oldies181,pop181,rock181,techno181,urban181
#eight181,nine181

proc fm181* =
 while true:
  const sub = "181FM"
  clear()
  var j = false
  say fgYellow,fmt"PNimRP > {sub}"
  sayIter 4,fgGreen,fmt"{sub} Station Playing Music:"
  sayIter 5,fgBlue,"""1 80s
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
Q Quit
R Return"""
  while true:
   sleep 100
   case getch():#[
    of '1': eight181(); break
    of '2': nine181(); break ]#
    of '3': comedy181(); break
    of '4': country181(); break
    of '5': easy181(); break
    of '6': latin181(); break
    of '7': oldies181(); break
    of '8': pop181(); break
    of '9': rock181(); break
    of 'A','a': techno181(); break
    of 'B','b': urban181(); break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
