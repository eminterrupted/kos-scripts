@lazyGlobal off.

parameter missionTag is core:tag, primeCore is core.

print "Resetting bootloader".

local arcBoot to "0:/boot/_bl.ks".
local locBoot to "/boot/_bl.ks".

if core:part:tag <> missionTag set core:part:tag to missionTag.

copyPath(arcBoot, locBoot).
set primeCore:bootfilename to locBoot.
primeCore:activate.