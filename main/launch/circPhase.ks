@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").

DispMain(scriptPath()).

local peOverride to false.
local tgtPe to -1.

if param:length > 0 
{
    set tgtPe to param[0].
    set peOverride to true.
}

// Vars
local cTag to core:tag:split("|").
local lp to list().
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
set lp to readJson(lpPath).

if not peOverride
{
    set tgtPe to lp[0].
}
local payloadStage to choose cTag[1] if cTag:length > 1 else 0.

local sVal to ship:facing.
local tVal to 0.

// local avgStageWaitTime to 1.02.

lock steering to sVal.
lock throttle to tVal.

// Arm Systems
ArmAutoStaging(payloadStage + 1).

// Calculations
OutMsg("Calculating Burn Parameters").
local dv        to CalcDvBE(ship:periapsis, ship:apoapsis, tgtPe, ship:apoapsis, ship:apoapsis)[1].
local burnDur   to CalcBurnDur(dv).

local mnvTime   to time:seconds + eta:apoapsis. // Since this is a simple circularization, we are just burning at apoapsis.
local burnETA   to mnvTime - burnDur[3].        // Uses the value of halfDur - totalStaging time over the half duration
local fullDur   to burnDur[0].                  // Full duration, no staging time included (for display only)
set g_MECO      to burnETA + fullDur.           // Expected cutoff point with full duration, does not take staging into account (ArmAutoStaging() will do this automatically)
//local l_MECO    to burnEta + burnDur[1].        // Expected cutoff point with full duration and staging estimates

// Uncomment below to see the maneuver that will be executed in map view assumed you have the ability in career mode
// if career():canMakeNodes
// {
//    local mnv to node(time:seconds + eta:apoapsis, 0, 0, dv).
//    add mnv.
// }

OutMsg("DV Needed: " + round(dv, 1) + "m/s").
Terminal:Input:Clear.
until time:seconds >= burnETA 
{
    set sVal to heading(compass_for(ship, ship:prograde), 0, 0).
    DispBurn(dv, burnEta - time:seconds, fullDur).
    DispTelemetry().
    
    if CheckWarpKey()
    {
        InitWarp(burnEta, "Burn ETA", 15, true).
        Terminal:Input:Clear.
    }
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
    DispTelemetry().
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
