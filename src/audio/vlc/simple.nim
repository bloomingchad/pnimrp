import helper

when isMainModule:
  #let url = "https://nl.ah.fm/mobile"
  let url1 = "https://listen.181fm.com/181-jammin_128k.mp3"
  var Handle = libvlcHandle.new()

  Handle = initNewCtx(Handle)
  Handle.setAllyOptionsVlc()
  Handle.allocateJobVlc(url1)
  Handle.playPlayer()
  ## sleep(5)
  ## ^^^!!!small delay to call is_play
  ## while libvlc.mediaPlayerIsPlaying(Handle.mediaPlayerCtx):
  while true:
    continue
    ##  poll loop
    ## printf("nowplaying: %s\n", getCurrentMediaTitleVlc(libvlc_handle));
    ## fflush(stdout);
    ## ^^^^ only written to stdout when flushed

  deinitPlayer(Handle)
