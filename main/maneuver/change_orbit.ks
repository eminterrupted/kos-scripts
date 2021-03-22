@lazyGlobal off.
clearScreen.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtPe is 125000,
          tgtAp is 7500000,
          tgtArgPe is 0.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Variables
local burnAnomaly   to mod(360 + tgtArgPe - ship:orbit:argumentofperiapsis, 360).     
local burnTime      to list().
local dvNeeded      to list().
local mnvTime       to nav_eta_to_ta(ship:orbit, burnAnomaly).
local tgtOrbit      to createOrbit(
    ship:orbit:inclination,
    nav_ecc(tgtPe, tgtAp, ship:body),
    nav_sma(tgtPe, tgtAp, ship:body),
    ship:orbit:LAN,
    mod((ship:orbit:LAN + 360) - burnAnomaly, 360),
    0,
    time:seconds,
    ship:body
    ).

// Control locks
local sVal          to lookDirUp(ship:prograde:vector, sun:position).
local tVal          to 0.
lock  steering      to sVal.
lock  throttle      to tVal.

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
disp_msg("Calculating burn data").

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_hohmann_orbit(ship:orbit, tgtOrbit, tgtArgPe).
disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

// Transfer burn
set burnTime to mnv_burn_times(dvNeeded[0], mnvTime).
disp_info("Burn duration: " + round(burnTime[1], 1)).
mnv_exec_circ_burn(dvNeeded[0], mnvTime, burnTime[0]).

// Check if we need to adjust pe
if not util_check_range(ship:periapsis, tgtPe - 500, tgtPe + 500)
{
    // Calculate our burnEta for the circ burn
    set mnvTime  to nav_eta_to_ta(ship:orbit, 180).
    set burnTime to mnv_burn_times(dvNeeded[1], mnvTime).
    disp_info("Burn duration: " + round(burnTime[1] / 2)).
    mnv_exec_circ_burn(dvNeeded[1], mnvTime, burnTime[0]).
}