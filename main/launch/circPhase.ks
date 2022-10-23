@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").

DispMain(scriptPath()).

local peOverride to false.

local tgtPe to max(ship:orbit:apoapsis, ship:orbit:periapsis).
local tgtAp to max(ship:orbit:apoapsis, ship:orbit:periapsis).
local tgtInc to 0.
local tgtLAN to -1.
local tgtRoll to 0.

if params:length > 0
{
    set tgtAp to params[0].
    set tgtPe to params[1].
    set tgtInc to params[2].
    set tgtLAN to params[3].
    set tgtRoll to params[4]. 
}

// Vars
local cTag to core:tag:split("|").
local lpPath to "".

local volIdx to 1.
until false
{
    if exists(volIdx + ":/lp.json") 
    {
        set lpPath to volIdx + ":/lp.json".
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        set lpPath to "0:/data/lp.json".
        break.
    }
    else
    {
        set volIdx to volIdx + 1.
    }
}
if exists(lpPath)
{
    set lp to readJson(lpPath).
}
else
{
    set lp to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).
}

if not peOverride
{
    set tgtPe to lp[0].
}
local payloadStage to choose cTag[1] if cTag:length > 1 else 0.

set sVal to ship:facing.
set tVal to 0.

// local avgStageWaitTime to 1.02.

lock steering to sVal.
lock throttle to tVal.

// Arm Systems
ArmAutoStaging(payloadStage + 1).

// Calculations
OutMsg("Calculating Burn Parameters").
local dv to list().
local burnDur to list().
local mnvTime to 0.
local burnETA to 0.
local fullDur to 0.
//local l_MECO    to burnEta + burnDur[1].        // Expected cutoff point with full duration and staging estimates

calcBurnData().

// Uncomment below to see the maneuver that will be executed in map view assumed you have the ability in career mode
// if career():canMakeNodes
// {
//    local mnv to node(time:seconds + eta:apoapsis, 0, 0, dv).
//    add mnv.
// }

Terminal:Input:Clear.
until time:seconds >= burnETA 
{
    OutMsg("DV Needed: " + round(dv, 1) + "m/s").
    set sVal to heading(compass_for(ship, ship:prograde), 0, 0).
    DispBurn(dv, burnEta - time:seconds, fullDur).
    DispLaunchTelemetry(lp).
    
    set g_termChar to GetInputChar().
    if g_termChar = Terminal:Input:HomeCursor
    {
        OutMsg("Recalculating burn data").
        OutInfo().
        OutInfo2().
        calcBurnData().
    }
    else if g_termChar = Terminal:Input:Enter
    {
        InitWarp(burnEta, "Burn ETA", 15, true).
    }
    Terminal:Input:Clear.
    wait 0.01.
}

OutMsg("Orbital insertion phase").
OutInfo().
OutInfo2().
set tVal to 1.
wait 0.05.

until time:seconds >= g_MECO
{
    if g_abortSystemArmed and ship:periapsis < body:atm:height and abort InitiateLaunchAbort().
    set sVal to heading(compass_for(ship, ship:prograde), 0, 0).
    OutInfo("Est time to g_MECO: " + round(g_MECO - time:seconds, 1) + "s   ").
    DispLaunchTelemetry(lp).
    wait 0.01.
}
set tVal to 0.
ag9 on.
OutInfo().

if hasNode remove nextNode.
OutMsg("Circularization phase complete").
wait 1.

ag9 off.
deletePath("1:/lp.json").

OutMsg("Launch complete").

wait 1.

if CheckPartSet("launch")
{
    OutMsg("Deploying 'launch' partSet").
    DeployPartSet("launch").
}

OutMsg("Deploying untagged partSet").
DeployPartSet().

OutMsg("Deployment complete").


// Helper function
local function calcBurnData
{
    set dv        to CalcDvBE(ship:periapsis, ship:apoapsis, tgtPe, ship:apoapsis, ship:apoapsis)[1].
    set burnDur   to CalcBurnDur(dv).

    set mnvTime   to time:seconds + eta:apoapsis. // Since this is a simple circularization, we are just burning at apoapsis.
    set burnETA   to mnvTime - burnDur[3].        // Uses the value of halfDur - totalStaging time over the half duration
    set fullDur   to burnDur[0].                  // Full duration, no staging time included (for display only)
    set g_MECO      to burnETA + fullDur.           // Expected cutoff point with full duration, does not take staging into account (ArmAutoStaging() will do this automatically)
}