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
local tgtAp         to launchPlan:tgtAp.
local tgtPe         to launchPlan:tgtPe.
local azCalcObj     to launchPlan:lazObj.
local mnvTime       to time:seconds + eta:apoapsis.
//local stPe          to ship:periapsis.

// Control
local rVal          to launchPlan:tgtRoll.
local sVal          to heading(l_az_calc(azCalcObj), 0, rVal).
local tVal          to 0.
lock steering       to sVal.
lock throttle       to tVal.

// Get dv and duration of burn
//local dv            to mnv_dv_hohmann(stPe, tgtPe)[1].
//local dv            to mnv_dv_hohmann_velocity(stPe, tgtPe, tgtAp, ship:body)[1].
local dv            to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtPe, tgtPe, tgtAp, ship:body)[1].
local burnTime      to mnv_burn_times(dv, mnvTime).
local burnETA       to burnTime[0].
local burnDur       to burnTime[1].
local mecoTS        to burnETA + burnDur.
local tgtVelocity   to velocityAt(ship, mnvTime):orbit:mag + dv.
lock  dvToGo        to abs(tgtVelocity - ship:velocity:orbit:mag).
    
disp_msg("dv needed: " + round(dv, 2)).
disp_info("Burn duration: " + round(burnDur, 1)).

when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    disp_info("Staging").
    ves_safe_stage().
    disp_info().
    if stage:number > 0 preserve.
}

util_warp_trigger(burnETA).

until time:seconds >= burnETA
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    disp_mnv_burn(burnETA, dvToGo, burnDur).
}

set tVal to 1.
disp_msg("Executing burn").
until dvToGo <= 10
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    disp_mnv_burn(burnETA, dvToGo, mecoTS - time:seconds).
}

until dvToGo <= 0.1
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    set tVal to dvToGo / 10.
    disp_mnv_burn(burnETA, dvToGo, mecoTS - time:seconds).
}
set tVal to 0.

disp_msg("Maneuver complete!").
wait 1.
clearScreen.
//-- End Main --//