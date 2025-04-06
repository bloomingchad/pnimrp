# config.nims

when defined(simple):
  switch("define", "useJsmn")

else:
  switch("define", "statuscache") #if statuscache is buggy for you remove it
  switch("define", "asynclinkadv")
  #switch("define", "ssl") #for linkadvanced

when defined(asynclinkadv):
  switch("define", "ssl")

when defined(nlvm):
  switch("passL", "-lmpv")
