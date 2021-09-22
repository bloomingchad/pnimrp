proc fm181 =
 while true:
  const sub = "181FM"
  clear()
  var j:bool
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
   sleep 50
   case getch(): #[
    of '1':
     include eight181
     eight181()
     break
    of '2':
     include nine181
     nine181()
     break ]#
    of '3':
     include comedy181
     comedy181()
     break
    of '4':
     include country181
     country181()
     break
    of '5':
     include easy181
     easy181()
     break
    of '6':
     include latin181
     latin181()
     break
    of '7':
     include oldies181
     oldies181()
     break
    of '8':
     include pop181
     pop181()
     break
    of '9':
     include rock181
     rock181()
     break
    of 'A','a':
     include techno181
     techno181()
     break
    of 'B','b':
     include urban181
     urban181()
     break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
   sleep 70
  if j == true: break
