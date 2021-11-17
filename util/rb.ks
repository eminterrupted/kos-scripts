@lazyGlobal off.

parameter missionTag, primeCore is core.

print "Resetting bootloader".

local bootFile  to "/boot/_bl.ks".

set core:part:tag to missionTag.
copyPath("0:" + bootFile, primeCore:volume:name + ":" + bootFile).
set primeCore:bootfilename to bootFile.
primeCore:activate.