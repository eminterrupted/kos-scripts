@lazyGlobal off.
clearScreen.

parameter tgtAlt,   // Altitude we wish to raise our orbit to
          burnAt.   // A timestamp for which to center the burn "node"

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").

local burnDur   to 0.
local burnEta   to 0.
local dvNeeded  to 0.
local halfDur   to 0.
local meco      to 0.
local stAlt     to 0.
local sun       to body("sun").

// Control locks
local sVal      to lookDirUp(ship:prograde:vector, sun:position).
local tVal      to 0.
lock  steering  to sVal.
lock  throttle  to tVal.

// Setup taging trigger
ves_staging_trigger().

disp_main().
disp_msg("Calculating burn data").
// Identify the current altitude, opposite the burnAt timestamp
// Faking this for now since we just need to circularize after launch
if round(burnAt) = round(time:seconds + eta:apoapsis) 
{
    set stAlt to ship:periapsis. 
}

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_prograde(tgtAlt, stAlt, ship:body).
disp_info("dv needed: " + round(dvNeeded, 2)).

// Calculate burn times
set burnDur to mnv_burn_dur(dvNeeded).
set halfDur to mnv_burn_dur(dvNeeded / 2).
disp_info("Burn duration: " + round(burnDur, 1)).

// Calculate burn ETA
set burnEta to burnAt - halfDur.

// Wait until burn ETA with 30s buffer
until time:seconds >= burnEta - 30
{
    disp_msg("Burn ETA: " + round(time:seconds - burnEta, 1)).
    disp_telemetry().
    wait 0.01.
}

// If warping, stop it
if warp > 0 set warp to 0.

// Wait until actual burn
until time:seconds >= burnEta
{
    set sVal to ship:prograde + r(0, mnv_pitch_ang(tgtAlt), 0).
    disp_msg("Burn ETA: " + round(time:seconds - burnEta, 1)).
    disp_telemetry().
    wait 0.01.
}
set meco to time:seconds + burnDur.
// Execute burn
set tVal to 1.
until time:seconds >= meco
{
    set sVal to ship:prograde + r(0, mnv_pitch_ang(tgtAlt), 0).
    disp_msg("Burn ETA: " + round(time:seconds - burnEta, 1)).
    disp_info("Burn duration: " + round(meco - time:seconds, 1)). 
    disp_telemetry().
    wait 0.01.
}
set tVal to 0.
disp_info().
disp_msg("Maneuver complete!").
wait 5.
clearScreen.