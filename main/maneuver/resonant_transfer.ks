@lazyGlobal off.
clearScreen. 

parameter tgt,
          numOrbits is 1.
          

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

if not hasTarget 
{
    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    set target to nav_orbitable(tgt).
}
else
{
    set tgt to target.
}

// Phase sampling
local p0    to nav_lng_to_degrees(ship:longitude).
wait 1.
local p1    to nav_lng_to_degrees(ship:longitude).
local phaseRate to abs(p1 - p0).

// Calculate resonant period and ap
local targetAngle   to mod(nav_lng_to_degrees(ship:longitude) - nav_lng_to_degrees(target:longitude)+ 360, 360).
local timeToAdd     to (targetAngle / phaseRate) / numOrbits.
local resonantPeriod to ship:orbit:period + timeToAdd.
local resonantSMA to nav_sma_from_period(resonantPeriod, ship:body).
local resonantAp  to resonantSMA - ship:body:radius.

print "phaseRate     : " + round(phaseRate, 5) at (2, 21).
print "targetPhase   : " + round(targetAngle, 2) at (2, 22).
print "current Period: " + round(ship:orbit:period, 1) at (2, 23).
print "resonantPeriod: " + round(resonantPeriod, 1) at (2, 24).
print "resonantAP    : " + round(resonantAp, 1) at (2, 25).
print "resonantSMA   : " + round(nav_sma(ship:periapsis, resonantAp)) at (2, 26).

// Calculate the burn params
local dvTransfer    to mnv_dv_hohmann_velocity(ship:apoapsis, ship:periapsis, resonantAp, resonantAp)[0].
local transferTime  to time:seconds + eta:periapsis.
local burnDur to mnv_burn_dur(dvTransfer).
local halfDur to mnv_burn_dur(dvTransfer / 2).
local burnETA to transferTime - halfDur.
disp_msg("dvTransfer: " + round(dvTransfer, 2)).
disp_info("Burn ETA : " + round(burnETA, 1) + "          ").
disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
mnv_exec_circ_burn(dvTransfer, transferTime, burnEta).

// Re-circularize
local dvCirc    to mnv_dv_hohmann_velocity(resonantAp, resonantAp, ship:periapsis, ship:periapsis)[1].
local circTime  to time:seconds + eta:periapsis + (ship:orbit:period * (numOrbits - 1)).
set burnDur     to mnv_burn_dur(dvTransfer).
set halfDur     to mnv_burn_dur(dvTransfer / 2).
set burnETA     to circTime - halfDur.
disp_msg("dvTransfer: " + round(dvTransfer, 2)).
disp_info("Burn ETA : " + round(burnETA, 1) + "          ").
disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
mnv_exec_circ_burn(dvCirc, circTime, burnEta).