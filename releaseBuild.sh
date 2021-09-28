CC="gcc"

CFLAGS="-d:release \
--verbosity:3 \
--stdout:off"

HINTS=" --hint:LineTooLong:off \
  --hint:XDeclaredButNotUsed:on \
  --hint:Path:off \
  --hint:Conf:off \
  --hint:Link:off \
  --hint:MsgOrigin:off"

nim c --cc:$CC $@ -o:player \
  $CFLAGS \
  $HINTS \
  src/player/player.nim &

nim c --cc:$CC $@ -o:pnimrp \
  $CFLAGS \
  $HINTS \
  src/pnimrp.nim

strip player &
strip pnimrp
