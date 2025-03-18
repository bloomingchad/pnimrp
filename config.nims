# config.nims

when defined(simple):
  switch("define", "useJsmn")

else:
  switch("define", "statuscache") #if statuscache is buggy for you remove it
  switch("define", "ssl") #for linkadvanced
