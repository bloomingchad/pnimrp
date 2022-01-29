import terminal, term

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
   case getch():
    of '1': menu sub,"listener/listener1","Section1"; break
    of '2': menu sub,"listener/listener2","Section2"; break
    of '3': menu sub,"listener/listener3","Section3"; break
    of '4': menu sub,"listener/listener4","Section4"; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
