# linkresolver.nim

import times, random, utils, os, asyncdispatch

proc resolveLink*(url: string): Future[LinkStatus] {.async.} =
  ## Simulates link resolution with 80% valid, 20% invalid ratio
  randomize()
  
  # Simulate delay (unchanged)
  #let delayMs = 1000 + rand(500) - rand(500)
  #sleep(delayMs)
  await sleepAsync 20

  # Return lsValid for 80% of cases (80/100 = 80%)
  if rand(99) < 80:  # 0-79 (80 values) = valid
    result = lsValid
  else:               # 80-99 (20 values) = invalid
    result = lsInvalid
