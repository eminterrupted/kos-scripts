
@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath():name).

local orbitTime to 0.
local orientation to "up-sun".

if param:length > 0 
{
    set orbitTime to param[0].
    if param:length > 1 set orientation to param[1].
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

local sentinel to ship:modulesnamed("SentinelModule")[0].
DoEvent(sentinel, "Start Object Tracking").

OutMsg("SENTINEL: Scanning for objects...").
OutHUD("Press End key in terminal to abort Sentinel mission").

until false
{
    set g_termChar to GetInputChar().

    if g_termChar = terminal:input:endcursor
    {
        OutMsg("Terminating Sentinel mission").
        wait 1.
        break.
    }

    set sVal to GetSteeringDir(orientation).
    
    DispOrbit().
    wait 0.1.
}