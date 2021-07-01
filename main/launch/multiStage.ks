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

local boostersDC    to lex().
local boostersTank  to lex().
local dropTanksDC   to lex().
local dropTanksTank to lex().

local hasBoosters   to false.
local hasDropTanks  to false.

local lesTower      to "".

local curTwr        to 0.
local endPitch      to 0.
local finalAlt      to 0.
local maxAcc        to 35.
local maxQ          to 0.145.
local maxTwr        to 2.
local stAlt         to 0.
local stTurn        to 750.
local stSpeed       to 100.
local twr_kP        to 0.225.
local twr_kI        to 0.004.
local twr_kD        to 0.00.
//local turnAlt   to max(body:atm:height - 10000, min(body:atm:height, tgtAlt * 0.2)).
//local turnAlt   to max(125000, min(body:atm:height, tgtAlt * 0.2)).
local turnAlt to choose 70000 if ship:body = body("kerbin") else 10000.

lock kGrav     to constant:g * ship:body:mass / (ship:body:radius + ship:altitude)^2.

// Flags
local hasFairing to choose true if ship:modulesNamed("ProceduralFairingDecoupler"):length > 0 
        or ship:modulesNamed("ModuleProceduralFairing"):length > 0 
        or ship:modulesNamed("ModuleSimpleAdjustableFairing"):length > 0 
    else false.

local hasLES to choose true if ship:partsDubbedPattern("Escape"):length > 0 else false.
if hasLES set lesTower to ship:partsdubbedpattern("Escape")[0].

// Control values
local rVal      to launchPlan:tgtRoll.
local sVal      to heading(90, 90, -90).
local tVal      to 0.
local tValLoLim to 0.63.

// throttle pid controllers
local accPid    to pidLoop().
local qPid      to pidLoop().
local twrPid    to pidLoop().

// Setup countdown
local cdStamp   to time:seconds + 10.
lock  countdown to time:seconds - cdStamp.
ag8 off.

// Set up the display
disp_terminal().
disp_main(scriptPath():name).

// Boosters check / enumeration
if ship:partsTaggedPattern("booster"):length > 0 
{
    set hasBoosters to true.
    set boosters    to ves_get_boosters().
    set boostersDC  to boosters[0].
    set boostersTank to boosters[1].
}

if ship:partsTaggedPattern("dropTank"):length > 0
{
    set hasDropTanks    to true.
    set dropTanks       to ves_get_drop_tanks().
    set dropTanksDC     to dropTanks[0].
    set dropTanksTank   to dropTanks[1].
}

// Fairing trigger
if hasFairing 
{
    when ship:altitude > body:atm:height + 250 then
    {
        ves_jettison_fairings().
    }
}


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
if ship:status = "PRELAUNCH" launch_engine_start(cdStamp).
set tVal to 1.
lock throttle to tVal.

until countdown >= -0.25 
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}
launch_pad_arms_retract().

until countdown >= 0
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}
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
until alt:radar >= 100
{
    disp_telemetry().
    wait 0.01.
}

// Roll program at 250m - rotates from 270 degrees to 0 or 180 based on
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

//set activeEng to ves_active_engines().
//local activeThr to { parameter engList. local thr to 0. for e in engList { set thr to thr + e:thrust.} return thr.}.
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
    //pid_readout().

    // Booster update
    if hasBoosters set hasBoosters to update_booster().
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    //print "Boosters: " + hasBoosters at (2, 35).

    disp_telemetry().
    wait 0.01.
}

// LES Tower jet
if hasLES 
{
    lesTower:getModule("ModuleEnginesFX"):doEvent("activate engine").
    lesTower:getModule("ModuleDecouple"):doEvent("decouple").
}

disp_msg("Post-turn burning to apoapsis").
until ship:apoapsis >= tgtAp * 0.995
{
    //set curThr   to activeThr(activeEng).
    set curTwr   to ship:availablethrust / (ship:mass * kGrav).

    local aVal   to choose max(tValLoLim, min(1, 1 + accPid:update(time:seconds, curAcc))) if curAcc >= maxAcc else 1.
    local twrVal to choose max(tValLoLim, min(1, 1 + twrPid:update(time:seconds, curTwr))) if curTwr >= maxTwr else 1.

    set sVal     to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal     to min(aVal, twrVal).
    // pid_readout().

    // Booster update
    if hasBoosters set hasBoosters to update_booster().
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    //print "Boosters: " + hasBoosters at (2, 35).

    disp_telemetry().
    wait 0.01.
}
disp_msg().

set finalAlt to choose tgtAp * 1 if ship:altitude >= body:atm:height else tgtAp * 1.00125.

disp_msg("Slow burn to apoapsis").
until ship:apoapsis >= finalAlt
{
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal to max(tValLoLim, min(1, 1 - (ship:apoapsis / tgtAp))).

    // Booster update
    if hasBoosters set hasBoosters to update_booster().
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    //print "Boosters: " + hasBoosters at (2, 35).
    
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
wait 2.5.
clearScreen.
//-- End Main --//

// Checks booster resources and stages when booster res falls below threshold
local function update_booster
{
    if boostersDC:length > 0
    {
        local boosterId     to boostersDC:length - 1.
        local boosterRes    to choose boostersTank[boosterId]:resources[1] if boostersTank[boosterId]:name:matchesPattern("Size1p5.Tank.05") else boostersTank[boosterId]:resources[0].
        if boosterRes:amount < 0.001
        {
            for dc in boostersDC[boosterId]
            {
                if dc:children:length > 0 
                {
                    //util_do_event(dc:getModule("ModuleAnchoredDecoupler"), "decouple").
                    disp_info("Separation Event: External Booster Loop ID [" + boosterId + "]").
                    boostersDC:remove(boosterId).
                    boostersTank:remove(boosterId).
                }
            }
            ves_safe_stage("booster").
            disp_info().
            accPid:reset.
            twrPid:reset.
            qPid:reset.
        }
        if boostersDC:length > 0 
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
    else 
    {
        return false.
    }
}