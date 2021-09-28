from os import commandLineParams,sleep
import client

proc main() =
 let parm = commandLineParams()
 let ctx = mpv_create()
 var val: cint = 1
 discard mpv_set_option(ctx, "", MPV_FORMAT_FLAG, addr(val))
 discard mpv_initialize ctx
 let file = allocCStringArray ["loadfile", parm[0]]
 discard mpv_command(ctx, file)
 while true:
  discard mpv_wait_event(ctx, 1)

main()
