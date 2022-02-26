@lazyGlobal off.
clearScreen.

// #include "0:/boot/_bl.ks"

parameter param to list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_l_az_calc.ks").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/globals").

DispMain(scriptPath(), false).

// Vars
// Launch params
local tgtPe     to 1250000.
local tgtAp     to 1250000.
local tgtInc    to 0.
local tgtLAN    to -1.
local tgtRoll   to 0.

// If the launch plan was passed in via param, override manual values
if param:length > 0
{
    set tgtPe to param[0].
    if param:length > 1 set tgtAp to param[1].
    if param:length > 2 set tgtInc to param[2].
    if param:length > 3 set tgtLAN to param[3].
    if param:length > 4 set tgtRoll to param[4]. 
}

local lpCache to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).

// Turn params
local altStartTurn to 2500.
local altGravTurn   to min(tgtAp / 2, 10000).

// Controls
local sVal to ship:facing.
local tVal to 0.
sas off.

// Core tag
local cTag to core:tag.
local stageLimit to choose 0 if cTag:split("|"):length <= 1 else cTag:split("|")[1]:tonumber.

// Begin  
lock steering to sVal. 

DispLaunchPlan(lpCache, list(plan:toupper, branch:toupper)).

// Write tgtPe to the local drive. If write fails, iterate through volumes. If no other volumes, write to archive.
local volIdx to 1. 
until false
{
    writeJson(list(tgtPe), volIdx + ":/lp.json").
    if exists(volIdx + ":/lp.json") 
    {
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        writeJson(list(tgtPe), "0:/data/lp.json").
        break.
    }
    else
    {
        set volIdx to volIdx + 1.
    }
}

// Wait for specific LAN goes here
if tgtLAN > -1
{
    runPath("0:/util/launchIntoLAN", tgtInc, tgtLAN).
}
else
{
    local ts to time:seconds.
    until false
    {
        if CheckInputChar(terminal:input:enter) break.
        if time:seconds >= ts
        {
            OutTee("Press Enter in terminal to launch", 0, 2.5).
            set ts to time:seconds + 5.
        }
        wait 0.05.
    }
}
clearScreen.
DispMain(scriptPath(), false).


// Arm systems
ArmAutoStaging(stageLimit).

// Calculate AZ here, write to disk for circularization. 
// We will write this to disk along with tgtPe and boost stage at launch
local azCalcObj to l_az_calc_init(tgtAp, tgtInc).

// Countdown to launch
LaunchCountdown(10).

// Launch commit
set tVal to 1.
lock throttle to tVal.

OutInfo().
OutInfo2().

OutMsg("Vertical Ascent").
until ship:bounds:BottomAltRadar >= altStartTurn
{
    DispTelemetry().
    wait 0.01.
}

OutInfo("Roll Program").
set sVal to heading(l_az_calc(azCalcObj), 90, 0).
until steeringManager:rollerror <= 0.1 and steeringManager:rollerror >= -0.1
{
    DispTelemetry().
    wait 0.01.
}
OutInfo().

until ship:bounds:BottomAltRadar >= altStartTurn or ship:altitude >= tgtAp
{
    DispTelemetry().
    wait 0.01.
}
set altStartTurn to ship:altitude.

OutMsg("Pitch Program").
until (ship:altitude >= altGravTurn and ship:apoapsis >= tgtAp * 0.5) or ship:apoapsis >= tgtAp * 0.975
{   
    set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), 0).
    DispTelemetry().
    wait 0.01.
}

OutMsg("Horizontal Velocity Program").
until ship:apoapsis >= tgtAp * 0.9995
{
    local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
    local adjAng to max(0, lAng - ((ship:altitude - altGravTurn) / 1000)).
    set sVal to heading(l_az_calc(azCalcObj), adjAng, 0).
    DispTelemetry().
    wait 0.01.
}
set tVal to 0.
OutInfo("Engine Cutoff").

OutMsg("Ascent phase complete").