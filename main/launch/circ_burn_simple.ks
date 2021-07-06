@lazyGlobal off.
clearScreen.

parameter launchPlan.

runOncePath("0:/lib/lib_file").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/kslib/lib_l_az_calc.ks").

// Circ burn below here
clearScreen.
disp_main(scriptPath()).
disp_msg("Calculating circ burn data").

// Variables
local tgtAlt        to launchPlan:tgtPe.
local azCalcObj     to launchPlan:lazObj.
local mnvTime       to time:seconds + eta:apoapsis.
local stAlt         to ship:periapsis.

// Control
local sVal          to heading(l_az_calc(azCalcObj), 0, 0).
local tVal          to 0.
lock steering       to sVal.
lock throttle       to tVal.

// Get dv and duration of burn
local dv            to mnv_dv_hohmann(stAlt, tgtAlt)[1].
local burnTime      to mnv_burn_times(dv, mnvTime).
local burnETA       to burnTime[0].
local burnDur       to burnTime[1].
local mecoTS        to burnETA + burnDur.
    
disp_msg("dv needed: " + round(dv, 2)).
disp_info("Calculated Burn Duration: " + round(burnDur, 1)).

when ship:maxThrust <= 0.1 and throttle > 0 then {
    disp_info("Staging").
    ves_safe_stage().
    disp_info().
    if stage:number > 0 preserve.
}

util_warp_trigger(burnETA - 30).

until time:seconds >= burnETA
{
    set sVal to heading(l_az_calc(azCalcObj), 0, 0).
    disp_mnv_burn(burnETA, 0, burnDur).
    disp_telemetry().
}

set tVal to 1.
disp_msg("Executing burn").
until time:seconds >= mecoTS
{
    set sVal to heading(l_az_calc(azCalcObj), 0, 0).
    disp_mnv_burn(burnETA, 0, mecoTS - time:seconds).
    disp_telemetry().
}
set tVal to 0.

disp_msg("Maneuver complete!").
wait 1.
clearScreen.
//-- End Main --//