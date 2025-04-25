# config.nims

when defined(simple):
  switch("define", "useJsmn")

else:
  switch("define", "statuscache") #if statuscache is buggy for you remove it
  switch("define", "asynclinkadv")
  switch("define", "ssl")

#when defined(asynclinkadv):
#  switch("define", "ssl")

when defined(nlvm):
  switch("passL", "-lmpv")

when not defined(dev):
  switch("define", "release")

switch("define", "volumeFade")

switch("warning", "UnusedImport:off")
switch("hint", "XDeclaredButNotUsed:off")
switch("hint", "Conf:off")
