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
local tgtAlt    to launchPlan:tgtAp.
local azCalcObj to launchPlan:lazObj.

local activeEng to list().
local curThr    to 0.
local curTwr    to 0.
local endPitch  to 0.
local finalAlt  to 0.
local maxAcc    to 35.
local maxQ      to 0.145.
local maxTwr    to 2.
local stAlt     to 0.
local stTurn    to 750.
local stSpeed   to 100.
local twr_kP    to 0.15.
local twr_kI    to 0.015.
local twr_kD    to 0.
//local turnAlt   to max(body:atm:height - 10000, min(body:atm:height, tgtAlt * 0.2)).
//local turnAlt   to max(125000, min(body:atm:height, tgtAlt * 0.2)).
local turnAlt to 60000.

lock kGrav     to constant:g * ship:body:mass / (ship:body:radius + ship:altitude)^2.

// Flags
local hasFairing to choose true if ship:modulesNamed("ProceduralFairingDecoupler"):length > 0 
    or ship:modulesNamed("ModuleProceduralFairing"):length > 0 
    or ship:modulesNamed("ModuleSimpleAdjustableFairing"):length > 0 
else false.

// Control values
local rVal      to launchPlan:tgtRoll.
local sVal      to heading(90, 90, -90).
local tVal      to 0.
local tValLoLim to 0.55.

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


// Fairing trigger
if hasFairing 
{
    when ship:altitude > body:atm:height + 250 then
    {
        ves_jettison_fairings().
    }
}

//-- Main --//
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
launch_engine_start(cdStamp).
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
        set activeEng to ves_active_engines().
        disp_info().
        accPid:reset.
        if stage:number > 0 preserve.
}