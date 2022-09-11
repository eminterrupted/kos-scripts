@lazyGlobal off.
clearScreen.

// #include "0:/boot/_bl.ks"

parameter lPlan to list().

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
if lPlan:length > 0
{
    set tgtAp to lPlan[0].
    set tgtPe to lPlan[1].
    set tgtInc to lPlan[2].
    set tgtLAN to lPlan[3].
    set tgtRoll to lPlan[4]. 
}
else 
{
    set lPlan to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).
}
local lpCache to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).

// Turn params
//local boundsBox     to ship:bounds.
local altRoll       to ship:altitude + 250.
local altStartTurn  to 750.
local altGravTurn   to 50000.
local spdStartTurn  to 75.

// Boosters
local boosterObj to lex().

// Controls
local rVal to tgtRoll.
set sVal to ship:facing.
set tVal to 0.

// Core tag
local cTag to core:tag.
local stageLimit to choose 0 if cTag:split("|"):length <= 1 else cTag:split("|")[1]:toNumber(0).
// Optional second core
local core2 to "".

OutTee("Hi I AM SpIcY AF", 0, 2.5).
wait 0.25.
OutHUD("Hello SpIcY AF, I am MiSs SuPeR SpIcE", 2).

// Begin  
LaunchPadGen(true).
lock steering to sVal. 

DispLaunchPlan(lpCache, list(plan:toupper, branch:toupper)).


// Write the launch plan to the local drive. 
// If write fails, iterate through volumes. If no other volumes, write to archive.
from { local volIdx to 1.} until volIdx > buildList("volumes"):length step { set volIdx to volIdx + 1.} do
{
    writeJson(lPlan, volIdx + ":/lp.json").
    writeJson(lPlan, "0:/data/lp.json").
    if exists(volIdx + ":/lp.json") break.
}

// Gets any special saturn or soyuz auxiliary launch pad parts that need special early handling
local padAuxParts to ship:partsNamedPattern("AM.MLP.*(Crane|DamperArm|CrewElevatorGemini|SoyuzLaunchBaseGantry|SoyuzLaunchBaseArm)").
if padAuxParts:length > 0 
{
    RetractAuxPadStructures(padAuxParts, true).
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
        local msgs to CheckMsgQueue().
        if msgs:contains("launchCommit")
        {
            set core2 to msgs[1].
            break.
        }
        else if time:seconds >= ts
        {
            OutTee("Press Enter in terminal to launch", 0, 2.5).
            set ts to time:seconds + 5.
        }
        wait 0.05.
    }

}

// Setup the terminal
clearScreen.
DispMain(scriptPath(), false).

// Get booster on vessel, if any
set boosterObj to GetBoosters().

// Arm systems
ArmAutoStaging(stageLimit).
ArmLESJettison(82500).
ArmFairingJettison("alt+", body:atm:height - 5000, "ascent").
set g_boosterSystemArmed to ArmBoosterSeparation(boosterObj).
set g_abortSystemArmed to SetupAbortGroup(Ship:RootPart).

// Calculate AZ here
local azCalcObj to l_az_calc_init(tgtAp, tgtInc).

// Countdown to launch
LaunchCountdown(10).

// Launch commit
set tVal to 1.
lock throttle to tVal.
HolddownRetract().
if missionTime <= 0.01 stage.  // Release launch clamps at T-0.

if core2 <> "" 
{
    SendMsg(core2, "CountdownComplete"). // A flag used for other scripts to denote that launch has occured
}

OutInfo().
OutInfo2().

OutMsg("Vertical Ascent").
until ship:altitude >= altRoll
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    DispLaunchTelemetry(lpCache).
    wait 0.01.
}

OutInfo("Roll Program").
set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
until steeringManager:rollerror <= 0.1 and steeringManager:rollerror >= -0.1
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    DispLaunchTelemetry(lpCache).
    wait 0.01.
}
OutInfo().

until ship:altitude >= altStartTurn or ship:verticalspeed >= spdStartTurn 
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    DispLaunchTelemetry(lpCache).
    wait 0.01.
}
set altStartTurn to ship:altitude.

OutMsg("Pitch Program").
until (ship:altitude >= altGravTurn and ship:apoapsis >= tgtAp * 0.5) or ship:apoapsis >= tgtAp * 0.975
{   
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), rVal).
    DispLaunchTelemetry(lpCache).
    wait 0.01.
}

OutMsg("Horizontal Velocity Program").
until ship:apoapsis >= tgtAp * 0.9995
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
    local adjAng to max(0, lAng - ((ship:altitude - altGravTurn) / 1000)).
    set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
    DispLaunchTelemetry(lpCache).
    wait 0.01.
}
set tVal to 0.
OutInfo("Engine Cutoff").

OutMsg("Boost phase complete").