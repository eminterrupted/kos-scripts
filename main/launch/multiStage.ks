@lazyGlobal off.
clearScreen.

parameter launchPlan.

// load dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/kslib/lib_navigation").

// variables
local tgtAp    to launchPlan:tgtAp.
local tgtInc   to launchPlan:tgtInc.
local azCalcObj to l_az_calc_init(tgtAp, tgtInc).

// local activeEng to list().
// local curThr    to 0.
local boosters      to list().
local dropTanks     to list().

local hasBoosters   to false.
local hasDropTanks  to false.

local hasLES        to false.
local lesTower      to "".
local lesTowerList  to list().

local curTwr        to 0.
local endPitch      to 0.
local finalAlt      to 0.
local maxAcc        to 35.
local maxQ          to 0.175.
local maxTwr        to 2.25.
local stAlt         to 0.
local stTurn        to 750.
local stSpeed       to 100.
local twr_kP        to 0.225.
local twr_kI        to 0.004.
local twr_kD        to 0.00.
local turnAlt       to round(body:atm:height * 0.875).

lock kGrav     to constant:g * ship:body:mass / (ship:body:radius + ship:altitude)^2.

// Flags
// Fairings
local hasFairing to choose true if ship:modulesNamed("ProceduralFairingDecoupler"):length > 0 
        or ship:modulesNamed("ModuleProceduralFairing"):length > 0 
        or ship:modulesNamed("ModuleSimpleAdjustableFairing"):length > 0 
    else false.

// LES
set lesTowerList to ship:partsDubbedPattern("escape").
set hasLES to choose true if lesTowerList:length > 0 else false.
if hasLES set lesTower to lesTowerList[0].

// Control values
local rVal      to launchPlan:tgtRoll.
local sVal      to heading(90, 90, -90).
local tVal      to 0.
local tValLoLim to 0.63.

// throttle pid controllers
local accPid    to pidLoop().
local qPid      to pidLoop().
local twrPid    to pidLoop().

// Set up the display
disp_terminal().
disp_main(scriptPath():name).

// Boosters check / enumeration
if ship:partsTaggedPattern("booster"):length > 0 
{
    set hasBoosters to true.
    set boosters    to ves_get_boosters().
}

if ship:partsTaggedPattern("dropTank"):length > 0
{
    set hasDropTanks    to true.
    set dropTanks       to ves_get_drop_tanks().
}

// Fairing trigger
if hasFairing 
{
    when ship:altitude > body:atm:height + 250 then
    {
        ves_jettison_fairings().
    }
}

launch_pad_fallback_partial().  // If we have a strongback tower, partially retract it prior to commencing the countdown

// Setup countdown
local cdStamp   to time:seconds + 10.
lock  countdown to time:seconds - cdStamp.
ag8 off.

//-- Main --//
sas off.
lock steering to sVal.
lock throttle to tVal.

// Countdown
until countdown >= -4 
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}
launch_pad_gen(false).

until countdown >= -1.5
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}

if ship:status = "PRELAUNCH" 
{
    launch_engine_start(cdStamp).
    set tVal to 1.
}
launch_pad_arms_retract().
launch_pad_fallback_full().
until countdown >= 0
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}
set tVal to 1.
lock throttle to tVal.
launch_pad_holdowns_retract().
if missionTime <= 0.01 stage.  // Release launch clamps at T-0.
ag8 on. // Action group cue for liftoff
ag10 off.   // Reset ag10 (is true to initiate launch)
unlock countdown.
disp_info().
disp_info2().
// End countdown

// Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 then
{
        disp_info("Staging").
        ves_safe_stage().
        //set activeEng to ves_active_engines().
        disp_info().
        accPid:reset.
        twrPid:reset.
        if stage:number > 0 preserve.
}

disp_msg("Vertical ascent").
until alt:radar >= 150
{
    disp_telemetry().
    wait 0.01.
}

// Roll program at 150m - rotates from 270 degrees to 0 or 180 based on
// whether a crew member is present. 
set sVal to heading(l_az_calc(azCalcObj), 90, rVal).

disp_info("Roll program").
until ship:altitude >= stTurn or ship:verticalspeed >= stSpeed
{
    if ves_roll_settled() disp_info().
    disp_telemetry().
    wait 0.01.
}
disp_info().
// Store the altitude at which we reached the turn threshold
set stAlt to ship:altitude.

// Set up gravity turn pids
set qPid to pidLoop(10, 0, 0, -1, 1).
set qPid:setpoint to maxQ.

set accPid to pidLoop(0.02, 0, 0, -1, 1).
set accPid:setpoint to maxAcc.

set twrPid to pidLoop(twr_kP, twr_kI, twr_kD, -1, 1).
set twrPid:setpoint to maxTwr.

lock curAcc to ship:availableThrust / ship:mass.

disp_msg("Gravity turn").
until ship:altitude >= turnAlt or ship:apoapsis >= tgtAp * 0.975
{
    // Steering update
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).

    // Throttle update
    set curTwr to ship:availablethrust / (ship:mass * kGrav).
    
    local qVal      to choose max(tValLoLim, min(1, 1 + qPid:update(time:seconds, ship:q)))     if ship:q >= maxQ   else 1.
    local aVal      to choose max(tValLoLim, min(1, 1 + accPid:update(time:seconds, curAcc)))   if curAcc >= maxAcc else 1.
    local twrVal    to max(tValLoLim, min(1, 1+ twrPid:update(time:seconds, curTwr))).
    local tValTemp  to min(qVal, aVal).
    set tVal to min(tValTemp, twrVal).
    
    // Booster update
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    
    disp_telemetry().
    wait 0.01.
}

// LES Tower jet
if hasLES 
{
    local towerJet to ves_jettison_les(lesTower).
    if towerJet 
    {
        disp_info("LES Tower jettisoned").
    }
    else
    {
        disp_info("LES Tower jettison failure!").
    }
}

disp_msg("Post-turn burning to apoapsis").
until ship:apoapsis >= tgtAp * 0.995
{
    set curTwr   to ship:availablethrust / (ship:mass * kGrav).

    local aVal   to choose max(tValLoLim, min(1, 1 + accPid:update(time:seconds, curAcc))) if curAcc >= maxAcc else 1.
    local twrVal to choose max(tValLoLim, min(1, 1 + twrPid:update(time:seconds, curTwr))) if curTwr >= maxTwr else 1.

    set sVal     to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal     to min(aVal, twrVal).
    
    // Booster update
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    
    disp_telemetry().
    wait 0.01.
}
disp_msg().
disp_info().

set finalAlt to choose tgtAp * 1 if ship:altitude >= body:atm:height else tgtAp * 1.00125.

disp_msg("Slow burn to apoapsis").
until ship:apoapsis >= finalAlt
{
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal to max(tValLoLim, min(1, 1 - (ship:apoapsis / tgtAp))).

    // Booster update
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    
    disp_telemetry().
    wait 0.01.
}
set tVal to 0.

disp_info("SECO").
wait 1.
disp_info().

disp_msg("Coasting to space").
until ship:altitude >= body:atm:height or ship:verticalspeed < 0
{
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    // Correction burn if needed
    if ship:apoapsis <= tgtAp * 0.995
    {
        disp_info("Correction burn").
        until ship:apoapsis >= tgtAp * 1.0015
        {
            set tVal to max(tValLoLim, min(1, 1 - (ship:apoapsis / tgtAp))).
        }
        disp_info().
    }
    set tVal to 0.
    disp_telemetry().
    wait 0.01.
}

disp_msg("Launch complete").
wait 0.5.
clearScreen.
if hasNode remove nextNode.
//-- End Main --//