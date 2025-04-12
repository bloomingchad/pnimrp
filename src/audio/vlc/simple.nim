import helper, os

proc example =
  #let url = "https://nl.ah.fm/mobile"
  let url1 = "https://listen.181fm.com/181-jammin_128k.mp3"
  let handle = new libvlcHandle

  handle.initNewCtx()
  defer: handle.deinitPlayer()

  handle.setAllyOptionsVlc()
  handle.allocateJobVlc(url1)
  handle.playPlayer()
  ## sleep(5)
  ## ^^^!!!small delay to call is_play
  ## while libvlc.mediaPlayerIsPlaying(Handle.mediaPlayerCtx):
  while true:
    sleep 50
    continue
    ##  poll loop
    ## printf("nowplaying: %s\n", getCurrentMediaTitleVlc(libvlc_handle));
    ## fflush(stdout);
    ## ^^^^ only written to stdout when flushed


when isMainModule:
  example()
