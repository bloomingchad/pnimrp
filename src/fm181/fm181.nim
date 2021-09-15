proc fm181() =
  var sub:string = "181FM"
  clsIter 0
  say 2,1,fgYellow,fmt"PNimRP > {sub}"
  say 2,4,fgGreen,fmt"{sub} Station Playing Music:"
  sayIter 6,5,fgBlue,fmt"""
1 80s
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
    var key = getKey()
    case key:
      of Key.None: discard  #[
      of '1':
        include eight181
        eight181()
      of '2':
        include nine181
        nine181() ]#
      of Key.Three:
        include comedy181
        comedy181()
      of Key.Four:
        include country181
        country181()
      of Key.Five:
        include easy181
        easy181()
      of Key.Six:
        include latin181
        latin181()
      of Key.Seven:
        include oldies181
        oldies181()
      of Key.Eight:
        include pop181
        pop181()
      of Key.Nine:
        include rock181
        rock181()
      of Key.A:
        include techno181
        techno181()
      of Key.B:
        include urban181
        urban181()
      of Key.R: main()
      of Key.Escape , Key.Q: exitProc();exitEcho()
      else:
        inv()
        fm181()
  sleep 20
