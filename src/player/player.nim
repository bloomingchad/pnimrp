from os import commandLineParams
import client

proc main() =
 let parm = commandLineParams()
 let inst = mpv_create()
 var val: cint = 1
 discard mpv_set_option(inst, "", MPV_FORMAT_FLAG, addr(val))
 discard mpv_initialize(inst)
 let file = allocCStringArray(["loadfile", parm[0]])
 discard mpv_command(inst, file)
 while true:
  discard mpv_wait_event(inst, 1)

main()
