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
local gearList      to list().

local hasBoosters   to false.
local hasDropTanks  to false.
local hasGear       to false.

local curTwr        to 0.
local endPitch      to 0.
local finalAlt      to 0.
local maxTwr        to 5.
local stAlt         to 0.
local stTurn        to 500.
local stSpeed       to 100.
local twr_kP        to 0.225.
local twr_kI        to 0.004.
local twr_kD        to 0.00.
local turnAlt       to 12500.

lock kGrav     to constant:g * ship:body:mass / (ship:body:radius + ship:altitude)^2.

// Control values
local rVal      to launchPlan:tgtRoll.
local sVal      to heading(90, 90).
local tVal      to 0.
local tValLoLim to 0.63.

// throttle pid controllers
local twrPid    to pidLoop().

// Setup countdown
local cdStamp   to time:seconds + 10.
lock  countdown to time:seconds - cdStamp.
ag8 off.

// Set up the display
disp_main(scriptPath():name).

// Part checks / enumeration
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

// Landing legs / gear
for p in ship:parts
{
    if p:hasModule("ModuleWheelDeployment")
    {
        gearList:add(p).
    }
    else if p:name:contains("landingleg") or p:title:contains("landing leg") 
    {
        gearList:add(p).
    }
}
if gearList:length > 0 set hasGear to true.

//-- Main --//
sas on.
lock throttle to tVal.

// Countdown
until countdown >= -4 
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}

until countdown >= -1.5
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.05.
}

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
set tVal to 1.
sas off.
lock steering to sVal.
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
        disp_info().
        if stage:number > 0 preserve.
}

disp_msg("Vertical ascent").
until alt:radar >= 75
{
    disp_telemetry().
    wait 0.01.
}

if hasGear
{
    disp_info("Gear up").
    gear off.
}

until alt:radar >= 175
{
    disp_telemetry().
    wait 0.01.
}

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

set twrPid to pidLoop(twr_kP, twr_kI, twr_kD, -1, 1).
set twrPid:setpoint to maxTwr.

disp_msg("Gravity turn").
until ship:altitude >= turnAlt or ship:apoapsis >= tgtAp * 0.975
{
    // Steering update
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).

    // Throttle update
    set curTwr to ship:availablethrust / (ship:mass * kGrav).
    
    local twrVal    to max(tValLoLim, min(1, 1+ twrPid:update(time:seconds, curTwr))).
    set tVal to twrVal.
    
    // Booster update
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).

    disp_telemetry().
    wait 0.01.
}

disp_msg("Post-turn burning to apoapsis").
until ship:apoapsis >= tgtAp * 0.995
{
    set curTwr   to ship:availablethrust / (ship:mass * kGrav).

    local twrVal to choose max(tValLoLim, min(1, 1 + twrPid:update(time:seconds, curTwr))) if curTwr >= maxTwr else 1.

    set sVal     to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal     to twrVal.

    // Booster update
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).

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
    if hasBoosters set hasBoosters to ves_update_booster(boosters).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    
    disp_telemetry().
    wait 0.01.
}
set tVal to 0.

disp_info("SECO").
wait 1.
disp_info().

disp_msg("Launch complete").
wait 1.
clearScreen.
//-- End Main --//