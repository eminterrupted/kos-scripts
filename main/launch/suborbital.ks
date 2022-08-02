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
local tgtPe     to 25000.
local tgtAp     to 250000.
local tgtInc    to -45.
local tgtLAN    to -1.
local tgtRoll   to 180.

// If the launch plan was passed in via param, override manual values
if lPlan:length > 0
{
    set tgtPe to lPlan[0].
    set tgtAp to lPlan[1].
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
local altStartTurn  to ship:altitude + 750.
local altGravTurn   to 50000.
local altFlatTrajectory to ship:body:atm:height * 0.80.
local spdStartTurn  to 75.

// Boosters / Engines
local boosterObj to lex().

// Controls
local rVal to tgtRoll.

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

// Write tgtPe and tgtInc to the local drive. 
// If write fails, iterate through volumes. If no other volumes, write to archive.
local volIdx to 1. 
until false
{
    writeJson(list(tgtPe, tgtInc), volIdx + ":/lp.json").
    if exists(volIdx + ":/lp.json") 
    {
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        writeJson(list(tgtPe, tgtInc), "0:/data/lp.json").
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
    // We need to retract Soyuz launch pad elements if present before handing off to launchIntoLAN
    if ship:partsDubbedPattern("mlp.soyuz"):length > 0 RetractSoyuzGantry().
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
    // Retract Soyuz launch pad elements if present AFTER user presses enter 
    // (avoids long wait times while gantry retracts)
    if ship:partsDubbedPattern("mlp.soyuz"):length > 0 RetractSoyuzGantry().
}

// Setup the terminal
clearScreen.
DispMain(scriptPath(), false).

// Get booster on vessel, if any
set boosterObj to GetBoosters().

// Arm systems
ArmAutoStaging(stageLimit).
ArmLESJettison(82500).
ArmFairingJettison("ascent", body:atm:height - 5000, "launch").
set g_boosterSystemArmed to ArmBoosterSeparation(boosterObj).
set g_abortSystemArmed to SetupAbortGroup(Ship:RootPart).
ArmEngCutoff().

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
    DispTelemetry().
    wait 0.01.
}

OutInfo("Roll Program").
set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
until steeringManager:rollerror <= 0.1 and steeringManager:rollerror >= -0.1
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    DispTelemetry().
    wait 0.01.
}
OutInfo().

until ship:altitude >= altStartTurn or ship:verticalspeed >= spdStartTurn or g_engBurnout
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    DispTelemetry().
    wait 0.01.
}
set altStartTurn to ship:altitude.

OutMsg("Pitch Program").
until ship:altitude >= altFlatTrajectory or (g_engBurnout and stage:number = g_stopStage)
{   
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), rVal).
    DispTelemetry().
    wait 0.01.
}

OutMsg("Horizontal Velocity Program").
until ship:apoapsis >= tgtAp * 0.9995 or (g_engBurnout and stage:number = g_stopStage)
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    //local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
    //local adjAng to max(0, lAng - ((ship:altitude - altGravTurn) / 1000)).
    local adjAng to 84.
    set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
    DispTelemetry().
    wait 0.01.
}

until ship:periapsis >= tgtPe or (g_engBurnout and stage:number = g_stopStage)
{
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    //local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
    //local adjAng to lAng - ((ship:altitude - altGravTurn) / 1000).
    local adjAng to 84.
    set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
    DispTelemetry().
    wait 0.01.
}
set tVal to 0.
OutInfo("Engine Cutoff").

OutMsg("Boost phase complete").

local coastStage to choose 1 if core:tag:split("|"):length <= 1 else core:tag:split("|")[1].
local ts to time:seconds + 10.

local orientation to "pro-body".
lock steering to sVal.

OutMsg("Waiting for booster staging").
until time:seconds >= ts
{
    set sVal to GetSteeringDir(orientation).
    DispTelemetry().
    wait 0.01.
}
until stage:number = coastStage
{
    wait until stage:ready.
    stage.
}
OutMsg("Booster staged").

set ts to time:seconds + 2.5.
until time:seconds >= ts
{
    DispTelemetry().
    wait 0.01.
}

if ship:crew:length > 0
{ 
    OutMsg("Control released to pilot").
    unlock steering.
    wait 2.5.
    
    OutMsg("Coasting to apoapsis").
    set ts to time:seconds + eta:apoapsis.
    InitWarp(ts, "near apoapsis").
    until time:seconds >= ts
    {
        DispTelemetry().
        wait 0.01.
    }
}
else
{
    OutMsg("Coasting to apoapsis in retrograde").
    set ts to time:seconds + eta:apoapsis.
    InitWarp(ts, "near apoapsis").
    until time:seconds >= ts
    {
        set sVal to GetSteeringDir(orientation).
        DispTelemetry().
        wait 0.01.
    }
}

until time:seconds >= ts
{
    DispTelemetry().
    wait 0.01.
}
sas off.
OutMsg("Suborbital script complete, preparing for reentry").
wait 2.5.