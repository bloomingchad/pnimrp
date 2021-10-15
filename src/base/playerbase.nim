from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from strutils import contains,repeat
from os import findExe,sleep,getCurrentDir
from termbase import warn,say,sayPos,inv,clear,exitEcho
from terminal import terminalWidth,setCursorXPos,getch,cursorUp,eraseLine,showCursor,styledWriteLine,fgCyan
from strformat import fmt
import client

proc exec*(x:string,args:openArray[string]; stream = false) =
 if stream: discard waitForExit startProcess(x,args=args,options={poUsePath,poParentStreams})
 else: discard waitForExit startProcess(x,args=args,options={poUsePath})

proc exit(ctx:ptr mpv_handle; term = false) =
 if term: mpv_terminate_destroy ctx
 echo ""
 showCursor()
 stdout.styledWriteLine fgCyan ,"when I die, just keep playing the records"
 echo fmt"free mem: {getFreeMem() / 1024} kB"
 echo fmt"total/max mem: {getTotalMem() / 1024} kB"
 echo fmt"occupied mem: {getOccupiedMem() / 1024} kB"
 quit QuitSuccess

proc init(parm:string,ctx: ptr mpv_handle) =
 let file = allocCStringArray ["loadfile", parm] #couldbe file,link,playlistfile
 var val: cint = 1
 check_error ctx.mpv_set_option("osc", MPV_FORMAT_FLAG, addr val)
 check_error mpv_initialize ctx
 check_error ctx.mpv_command file

proc player(parm:string) =
 let ctx = mpv_create()
 init parm, ctx
 var j = true
 var e = false
 var event = ctx.mpv_wait_event 1000
 while true:
  if j: sayPos 4, "Playing"; cursorUp(); j = false
  event = ctx.mpv_wait_event 1000
  if cast[mpv_event_id](event) == MPV_EVENT_SHUTDOWN: break
  if cast[mpv_event_id](event) == MPV_EVENT_IDLE: break
  sleep 50
  case getch():
   of 'p','m','P','M':
    setCursorXPos 4
    warn "Paused/Muted"
    cursorUp()
    mpv_terminate_destroy ctx
    sleep 50
    while true:
     case getch():
      of 'p','m','P','M':
       eraseLine()
       let ctx = mpv_create()
       init parm, ctx
       j = true
       break
      of 'r','R': e = true; break
      of 'q','Q': exit ctx
      else: inv()
   of '/':
    when defined linux: exec "amixer",["--quiet","set","PCM","7%+"]
    #when defined windows: exec "nircmd",["changesysvolume","5000"]
    warn "Volume+"
    sleep 500
    cursorUp()
    eraseLine()
   of 'r','R': mpv_terminate_destroy ctx; break
   of 'q','Q': exit ctx, term = true
   else: inv()
  if e: break

proc call*(sub:string; sect = ""; stat,link:string) =
 if link == "" or link.contains " ": warn "link dont exist or is invalid"; sleep 750
 else:
  clear()
  if sect == "": say fmt"PNimRP > {sub} > {stat}"
  else: say fmt"PNimRP > {sub} > {sect} > {stat}"
  sayPos 0,'-'.repeat(int terminalWidth() / 8) & '>'.repeat int terminalWidth() / 12
  player link
