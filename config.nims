# config.nims

when defined(simple):
  switch("define", "useJsmn")

else:
  switch("define", "statuscache") #if statuscache is buggy for you remove it
  switch("define", "asynclinkadv")
  switch("define", "ssl")
  switch("define", "volumeFade")
  switch("define", "asynccheckspinner")

#when defined(asynclinkadv):
#  switch("define", "ssl")

when defined(nlvm):
  switch("passL", "-lmpv")

when not defined(dev):
  switch("define", "release")

switch("warning", "UnusedImport:off")
switch("hint", "XDeclaredButNotUsed:off")
switch("hint", "Conf:off")
