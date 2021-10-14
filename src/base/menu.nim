import playerbase,termbase
from terminal import getch
from json import getStr, `{}`,JsonNode,parseJson
from os import sleep
from strformat import fmt

proc parseJ(x:string):JsonNode = parseJson readFile fmt"pnimrp.d/{x}.json"

proc endMenu3*(sub,sect,file:string) =
 let node = parseJ file
 var n,l:seq[string]
 for f in 1..3: n.add getStr node{ "Name" & $f }
 for f in 1..3: l.add getStr node{ "link" & $f }
 while true:
  var j = false
  drawMenu sub,sect,fmt"""1 {n[0]}
2 {n[1]}
3 {n[2]}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,n[0],l[0]; break
    of '2': call sub,sect,n[1],l[1]; break
    of '3': call sub,sect,n[2],l[2]; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu5*(sub,sect,file:string) =
 let node = parseJ file
 var n,l:seq[string]
 for f in 1..5: n.add getStr node{ "Name" & $f }
 for f in 1..5: l.add getStr node{ "link" & $f }
 while true:
  var j = false
  drawMenu sub,sect,fmt"""1 {n[0]}
2 {n[1]}
3 {n[2]}
4 {n[3]}
5 {n[4]}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,n[0],l[0]; break
    of '2': call sub,sect,n[1],l[1]; break
    of '3': call sub,sect,n[2],l[2]; break
    of '4': call sub,sect,n[3],l[3]; break
    of '5': call sub,sect,n[4],l[4]; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu10*(sub,sect,file:string) =
 let node = parseJ file
 var n,l:seq[string]
 for f in 1..10: n.add getStr node{ "Name" & $f }
 for f in 1..10: l.add getStr node{ "link" & $f }
 while true:
  var j = false
  drawMenu sub,sect,fmt"""1 {n[0]}
2 {n[1]}
3 {n[2]}
4 {n[3]}
5 {n[4]}
6 {n[5]}
7 {n[6]}
8 {n[7]}
9 {n[8]}
A {n[9]}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,n[0],l[0]; break
    of '2': call sub,sect,n[1],l[1]; break
    of '3': call sub,sect,n[2],l[2]; break
    of '4': call sub,sect,n[3],l[3]; break
    of '5': call sub,sect,n[4],l[4]; break
    of '6': call sub,sect,n[5],l[5]; break
    of '7': call sub,sect,n[6],l[6]; break
    of '8': call sub,sect,n[7],l[7]; break
    of '9': call sub,sect,n[8],l[8]; break
    of 'A','a': call sub,sect,n[9],l[9]; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break

proc endMenu15*(sub,sect,file:string) =
 let node = parseJ file
 var n,l:seq[string]
 for f in 1..15: n.add getStr node{ "Name" & $f }
 for f in 1..15: l.add getStr node{ "link" & $f }
 while true:
  var j = false
  drawMenu sub,sect,fmt"""1 {n[0]}
2 {n[1]}
3 {n[2]}
4 {n[3]}
5 {n[4]}
6 {n[5]}
7 {n[6]}
8 {n[7]}
9 {n[8]}
A {n[9]}
B {n[10]}
C {n[11]}
D {n[12]}
E {n[13]}
F {n[14]}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,n[0],l[0]; break
    of '2': call sub,sect,n[1],l[1]; break
    of '3': call sub,sect,n[2],l[2]; break
    of '4': call sub,sect,n[3],l[3]; break
    of '5': call sub,sect,n[4],l[4]; break
    of '6': call sub,sect,n[5],l[5]; break
    of '7': call sub,sect,n[6],l[6]; break
    of '8': call sub,sect,n[7],l[7]; break
    of '9': call sub,sect,n[8],l[8]; break
    of 'A','a': call sub,sect,n[9],l[9]; break
    of 'B','b': call sub,sect,n[10],n[10]; break
    of 'C','c': call sub,sect,n[11],n[11]; break
    of 'D','d': call sub,sect,n[12],n[12]; break
    of 'E','e': call sub,sect,n[13],n[13]; break
    of 'F','f': call sub,sect,n[14],n[14]; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
