# linkresolver.nim

import times, random, utils, os

proc resolveLinkSync*(url: string): LinkStatus =
  ## Simulates synchronous link resolution with a delay.
  ## Returns either lsValid or lsInvalid.

  randomize()

  # Simulate a delay between 500ms and 1500ms (1s +/- 500ms)
  let delayMs = 1000 + rand(500) - rand(500)
  sleep(delayMs)

  # Randomly return lsValid or lsInvalid
  if rand(1) == 0:
    result = lsValid
  else:
    result = lsInvalid