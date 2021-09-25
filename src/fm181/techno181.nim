from os import sleep
from terminal import getch
import ../base,json

proc techno181* =
 const sub = "181FM"
 const sect = "Techno"
 let node = parseJ "181FM/techno181.json"
 let Name01 = getStr node{"Name01"}
 let Name02 = getStr node{"Name02"}
 let Name03 = getStr node{"Name03"}
 let Name04 = getStr node{"Name04"}
 let Name05 = getStr node{"Name05"}
 let Name06 = getStr node{"Name06"}
 let Name07 = getStr node{"Name07"}
 let Name08 = getStr node{"Name08"}
 let Name09 = getStr node{"Name09"}
 let Name10 = getStr node{"Name10"}
 let link01 = getStr node{"link01"}
 let link02 = getStr node{"link02"}
 let link03 = getStr node{"link03"}
 let link04 = getStr node{"link04"}
 let link05 = getStr node{"link05"}
 let link06 = getStr node{"link06"}
 let link07 = getStr node{"link07"}
 let link08 = getStr node{"link08"}
 let link09 = getStr node{"link09"}
 let link10 = getStr node{"link10"}

 while true:
  var j = false
  drawMenuSect sub,sect,"1 " & Name01
  sayC "2 " & Name02
  sayC "3 " & Name03
  sayC "4 " & Name04
  sayC "5 " & Name05
  sayC "6 " & Name06
  sayC "7 " & Name07
  sayC "8 " & Name08
  sayC "9 " & Name09
  sayC "A " & Name10
  sayIter """R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01 ; break
    of '2': call sub,sect,Name02,link02 ; break
    of '3': call sub,sect,Name03,link03 ; break
    of '4': call sub,sect,Name04,link04 ; break
    of '5': call sub,sect,Name05,link05 ; break
    of '6': call sub,sect,Name06,link06 ; break
    of '7': call sub,sect,Name07,link07 ; break
    of '8': call sub,sect,Name08,link08 ; break
    of '9': call sub,sect,Name09,link09 ; break
    of 'A','a': call sub,sect,Name10,link10 ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
