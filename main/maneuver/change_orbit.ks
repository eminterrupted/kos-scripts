@lazyGlobal off.
clearScreen.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtPe is 103500,
          tgtAp is 3060027,
          tgtArgPe is 90.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Variables
local burnAnomaly   to mod(360 + tgtArgPe - ship:orbit:argumentofperiapsis, 360).     
local burnDur       to 0.
local burnETA       to 0.
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
//set dvNeeded to mnv_dv_hohmann_orbit(ship:orbit, tgtOrbit, tgtArgPe).
set dvNeeded        to mnv_dv_hohmann_orbit_velocity(ship:orbit, tgtOrbit, burnAnomaly, ship:body).
disp_msg("dv0: " + round(dvNeeded[0], 2) + "  |  dv1: " + round(dvNeeded[1], 2)).
wait 5.


if util_runmode() = 0 
{
    // Transfer burn
    set burnDur     to mnv_burn_dur(dvNeeded[0]).
    set burnETA     to mnvTime - mnv_burn_dur(dvNeeded[0] / 2).
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[0]).
    add mnvNode.
    disp_info("Burn duration: " + round(burnDur, 1)).
    mnv_exec_node_burn(mnvNode, burnEta, burnDur).
    //mnv_exec_circ_burn(dvNeeded[0], mnvTime, burnETA, burnDur).
    util_set_runmode(1).
}

if util_runmode() = 1
{
    // Arrival burn
    set mnvTime     to nav_eta_to_ta(ship:orbit, 180).
    set burnDur     to mnv_burn_dur(dvNeeded[1]).
    set burnETA     to mnvTime - mnv_burn_dur(dvNeeded[1] / 2).
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[1]).
    add mnvNode.
    disp_msg("dv1: " + round(dvNeeded[1], 2)).
    disp_info("Burn duration: " + round(burnDur, 1)).
    mnv_exec_node_burn(mnvNode, burnETA, burnDur).
    //mnv_exec_circ_burn(dvNeeded[1], mnvTime, burnETA, burnDur).
    util_set_runmode().
}