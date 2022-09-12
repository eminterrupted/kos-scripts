@lazyGlobal off.
clearScreen.

parameter params is list().

runpath("0:/lib/loadDep").

DispMain(scriptPath(), true).

local tgtAP to 500000.
local tgtPE to 500000.
local tgtInc to 0.
local tgtLAN to -1.
local tgtPhase to 0.

if params:length > 0
{
    set tgtPhase to params[0].
}

OutInfo("Select reference vessel").
until hasTarget
{
    wait 0.05.
}
set tgtVes to Target.
set tgtAP to tgtVes:apoapsis.
set tgtPE to tgtVes:periapsis.
set tgtInc to tgtVes:orbit:inclination.
set tgtLAN to tgtVes:orbit:LAN.

OutMsg("Target selected: " + tgtVes:name).
wait 1.

