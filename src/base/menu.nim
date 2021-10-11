import playerbase,termbase
from terminal import getch
from json import getStr, `{}`,JsonNode,parseJson
from os import sleep
from strformat import fmt

proc parseJ(x:string):JsonNode = parseJson readFile fmt"pnimrp.d/{x}.json"

proc endMenu3*(sub,sect,file:string) =
 let
  node = parseJ file
  Name01 = getStr node{"Name01"}
  Name02 = getStr node{"Name02"}
  Name03 = getStr node{"Name03"}
  link01 = getStr node{"link01"}
  link02 = getStr node{"link02"}
  link03 = getStr node{"link03"}
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01; break
    of '2': call sub,sect,Name02,link02; break
    of '3': call sub,sect,Name03,link03; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu5*(sub,sect,file:string) =
 let
  node = parseJ file
  Name01 = getStr node{"Name01"}
  Name02 = getStr node{"Name02"}
  Name03 = getStr node{"Name03"}
  Name04 = getStr node{"Name04"}
  Name05 = getStr node{"Name05"}
  link01 = getStr node{"link01"}
  link02 = getStr node{"link02"}
  link03 = getStr node{"link03"}
  link04 = getStr node{"link04"}
  link05 = getStr node{"link05"}
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
4 {Name04}
5 {Name05}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01; break
    of '2': call sub,sect,Name02,link02; break
    of '3': call sub,sect,Name03,link03; break
    of '4': call sub,sect,Name04,link04; break
    of '5': call sub,sect,Name05,link05; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu10*(sub,sect,file:string) =
 let
  node = parseJ file
  Name01 = getStr node{"Name01"}
  Name02 = getStr node{"Name02"}
  Name03 = getStr node{"Name03"}
  Name04 = getStr node{"Name04"}
  Name05 = getStr node{"Name05"}
  Name06 = getStr node{"Name06"}
  Name07 = getStr node{"Name07"}
  Name08 = getStr node{"Name08"}
  Name09 = getStr node{"Name09"}
  Name10 = getStr node{"Name10"}
  link01 = getStr node{"link01"}
  link02 = getStr node{"link02"}
  link03 = getStr node{"link03"}
  link04 = getStr node{"link04"}
  link05 = getStr node{"link05"}
  link06 = getStr node{"link06"}
  link07 = getStr node{"link07"}
  link08 = getStr node{"link08"}
  link09 = getStr node{"link09"}
  link10 = getStr node{"link10"}
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
4 {Name04}
5 {Name05}
6 {Name06}
7 {Name07}
8 {Name08}
9 {Name09}
A {Name10}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01; break
    of '2': call sub,sect,Name02,link02; break
    of '3': call sub,sect,Name03,link03; break
    of '4': call sub,sect,Name04,link04; break
    of '5': call sub,sect,Name05,link05; break
    of '6': call sub,sect,Name06,link06; break
    of '7': call sub,sect,Name07,link07; break
    of '8': call sub,sect,Name08,link08; break
    of '9': call sub,sect,Name09,link09; break
    of 'A','a': call sub,sect,Name10,link10; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu15*(sub,sect,file:string) =
 let
  node = parseJ file
  Name01 = getStr node{"Name01"}
  Name02 = getStr node{"Name02"}
  Name03 = getStr node{"Name03"}
  Name04 = getStr node{"Name04"}
  Name05 = getStr node{"Name05"}
  Name06 = getStr node{"Name06"}
  Name07 = getStr node{"Name07"}
  Name08 = getStr node{"Name08"}
  Name09 = getStr node{"Name09"}
  Name10 = getStr node{"Name10"}
  Name11 = getStr node{"Name11"}
  Name12 = getStr node{"Name12"}
  Name13 = getStr node{"Name13"}
  Name14 = getStr node{"Name14"}
  Name15 = getStr node{"Name15"}
  link01 = getStr node{"link01"}
  link02 = getStr node{"link02"}
  link03 = getStr node{"link03"}
  link04 = getStr node{"link04"}
  link05 = getStr node{"link05"}
  link06 = getStr node{"link06"}
  link07 = getStr node{"link07"}
  link08 = getStr node{"link08"}
  link09 = getStr node{"link09"}
  link10 = getStr node{"link10"}
  link11 = getStr node{"link11"}
  link12 = getStr node{"link12"}
  link13 = getStr node{"link13"}
  link14 = getStr node{"link14"}
  link15 = getStr node{"link15"}
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
4 {Name04}
5 {Name05}
6 {Name06}
7 {Name07}
8 {Name08}
9 {Name09}
A {Name10}
B {Name11}
C {Name12}
D {Name13}
E {Name14}
F {Name15}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01; break
    of '2': call sub,sect,Name02,link02; break
    of '3': call sub,sect,Name03,link03; break
    of '4': call sub,sect,Name04,link04; break
    of '5': call sub,sect,Name05,link05; break
    of '6': call sub,sect,Name06,link06; break
    of '7': call sub,sect,Name07,link07; break
    of '8': call sub,sect,Name08,link08; break
    of '9': call sub,sect,Name09,link09; break
    of 'A','a': call sub,sect,Name10,link10; break
    of 'B','b': call sub,sect,Name11,link11; break
    of 'C','c': call sub,sect,Name12,link12; break
    of 'D','d': call sub,sect,Name13,link13; break
    of 'E','e': call sub,sect,Name14,link14; break
    of 'F','f': call sub,sect,Name15,link15; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
