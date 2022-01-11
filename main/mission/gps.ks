@LazyGlobal off.
ClearScreen.

parameter params to list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local gpsStatus to "Disabled".
local orientation to "pro-sun".
local sVal to r(0, 0, 0).

if params:length > 0 {
    set orientation to params[0].
}

set sVal to GetSteeringDir(orientation).

// Enable the GPS module
OutMsg("Enabling GPS Module").
for m in Ship:ModulesNamed("ModuleGPSTransmitter") 
{
    if m:HasEvent("turn on gps") 
    {
        if DoEvent(m, "turn on gps") 
        {
            set gpsStatus to "Enabled".
        }
        else 
        {
            OutMsg("GPS module could not be enabled. Check transmitter.").
        }
    }
    else 
    {
        OutMsg("GPS module already enabled").
        set gpsStatus to "Enabled".
    }
}
wait 2.5.

OutMsg().
lock steering to sVal.

until false 
{
    set sVal to GetSteeringDir(orientation).
    DispGPS(gpsStatus, orientation).
}