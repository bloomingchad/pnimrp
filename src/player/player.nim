from os import commandLineParams
import client

let
 parm = commandLineParams()
 ctx = mpv_create()
 file = allocCStringArray ["loadfile", parm[0]] #couldbe file,link,playlistfile
var val: cint = 1

mpv_set_option(ctx, "", MPV_FORMAT_FLAG, addr val)
mpv_initialize ctx
mpv_command(ctx, file)

while true:
 discard mpv_wait_event(ctx, 1000)
