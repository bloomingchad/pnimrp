proc fm181() =
  var sub:string = "181FM"
  clear()
  echo """
PNimRP -> 181FM

181FM Station Playing Music:
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
    sleep 160
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
      of Key.Escape , Key.Q: exitEcho() ;exitProc()
      else:
        inv()
        fm181()
  tb.display()
  sleep(20)
