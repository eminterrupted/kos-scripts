@lazyGlobal off.

parameter primeCore is core.

print "Resetting bootloader".

local bootFile  to "/boot/bootLoader.ks".

if not primeCore:volume:name:contains("local") set primeCore:volume:name to "local".
copyPath("0:" + bootFile, "local:" + bootFile).
set primeCore:bootfilename to bootFile.
primeCore:activate.