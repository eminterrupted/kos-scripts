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

// Variables here
local boosterObj    to ves_get_boosters().

// Flags here
local doStaging     to false.
local deployFairing to false.
local dropBoosters  to false.
local hasBooster   to false.
local resetAccPid   to false.
local resetTwrPid   to false.
local resetQPid     to false.

// Init runmode
local runmode to util_init_runmode().

// Runmode loop
until runmode = -1
{
    // Flag checks
    if doStaging
    {
        disp_info("Staging").
        ves_safe_stage().
        set activeEng to ves_active_engines().
        disp_info().
        set resetAccPid to true.
        set resetTwrPid to true.
        set doStaging to false.
    }

    if hasBooster
    {
        if not ves_check_ext_tank(boosterObj)
        {
            ves_drop_booster(boosterObj).
            if boosterObj[0]:length = 0
            {
                set hasBooster to false.
            }
        }
    }

    if hasFairing
    {
        if ship:altitude >= body:atm:height + 250
        {
            ves_jettison_fairings().
            set hasFairing to false.
        }
    }

    if resetAccPid 
    {
        accPid:reset.
    }

    if resetQPid 
    {
        qPid:reset.
    }

    if resetTwrPid
    {
        twrPid:reset.
    }
    // End flag checks

    // Runmodes

    // Launch pad prep
    if runmode = 0 
    {
        set runmode to util_set_runmode(10).
    }

    // Countdown
    else if runmode = 10
    {

        set runmode to util_set_runmode(20).
    }

    // Liftoff
    else if runmode = 20
    {

        set runmode to util_set_runmode(30).
    }

    // Roll program
    else if runmode = 30
    {

        set runmode to util_set_runmode(40).
    }

    // Vertical ascent
    else if runmode = 40
    {
        
        set runmode to util_set_runmode(50).
    }

    // Gravity turn
    else if runmode = 50
    {

        set runmode to util_set_runmode(60).
    }

    // Post-gravity turn burn to apoapsis
    else if runmode = 60
    {

        set runmode to util_set_runmode(70).
    }

    // MECO
    else if runmode = 70
    {

        set runmode to util_set_runmode(80).
    }

    // Coast to space
    else if runmode = 80
    {

        if correctionNeeded set runmode to util_set_runmode(90).
        else if ship:altitude >= tgtAp set runmode to util_set_runmode(100).
    }

    // Correction burn
    else if runmode = 90
    {

        // Always set this back to coast to space once complete
        set runmode to util_set_runmode(80).
    }

    // Reach space
    else if runmode = 100
    {

        set runmode to -1.
    }

    // State checks (for detecting things like staging)
    if ship:availableThrust <= 0.01 and throttle > 0
    {
        set doStaging to true.
    }
}