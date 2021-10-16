@lazyGlobal off.
clearScreen.

parameter flip is false,
          corFactor is 2,
          wp is "active".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).
clearVecDraws().

// Variables
local vdCor         to vecDraw(v(0, 0, 0), v(0, 0, 0), rgb(0, 1, 0), "", 1.0, false).
local vdCorAxis     to vecDraw(v(0, 0, 0), v(0, 0, 0), rgb(0, 1, 0), "", 1.0, false).
local vdCorRet      to vecDraw(v(0, 0, 0), v(0, 0, 0), rgb(0, 1, 0), "", 1.0, false).
local vdPro         to vecDraw(v(0, 0, 0), v(0, 0, 0), rgb(0, 1, 0), "", 1.0, false).
local vdWp          to vecDraw(v(0, 0, 0), v(0, 0, 0), rgb(0, 1, 0), "", 1.0, false).

local sVal          to ship:facing.

if wp = "active" 
{
    for w in allWaypoints()
    {
        if w:isselected set wp to w.
    }
}
else if wp:typename = "string" 
{
    set wp to waypoint(wp).
} 
else if wp:typename <> "Waypoint"
{
    disp_msg("ERR: [" + wp + "] Not a known waypoint").
    disp_hud("ERR: [" + wp + "] Not a known waypoint", 2).
    print 1 / 0.
}

disp_msg("Horizontal mode - Press 0 for Vertical mode").
lock wpXcl       to vxcl(body:position, wp:position).
lock proXcl      to vxcl(body:position, ship:orbit:velocity:orbit).
lock errAng      to choose -vAng(wpXcl, proXcl) * corFactor if not flip else vAng(wpXcl, proXcl) * corFactor.
lock errAngRet   to choose -vAng(wpXcl, -proXcl) * corFactor if not flip else vAng(wpXcl, -proXcl) * corFactor.
lock corAng      to errAng * 2.
lock corAngAxis  to errAng + 90.
lock corAngRet   to errAngRet * 2.

lock corVec      to (ship:prograde - r(errAng, 0, 0)):vector * wp:position:mag.
lock corVecAxis  to choose (ship:prograde - r(mod(errAng - 90, 360), 0, 0)):vector * wp:position:mag if not flip else (ship:prograde - r(mod(errAng + 90, 360), 0, 0)):vector * wp:position:mag.
lock corVecRet   to -(ship:retrograde - r(errAng, 0, 0)):vector * wp:position:mag.
lock wpLatMag    to wpXcl:mag.
lock wpDist      to wp:geoPosition:distance.
lock wpPosMag    to wp:position:mag.

set sVal to corVecAxis.
lock steering to sVal.

ag10 off.
until ag10
{
    set sVal to corVecAxis.
    clearVecDraws().
    set vdCor       to vecDraw(ship:position, corVec, rgb(0.10, 1, 0.10), "Correction (" + round(corAng, 1) + ")", 1.0, true).
    set vdCorAxis   to vecDraw(ship:position, corVecAxis, rgb(1, 0, 1), "Rotated Correction (" + round(corAngAxis, 1) + ")", 1.0, true).
    set vdCorRet    to vecDraw(ship:position, corVecRet, rgb(1, 0.35, 0.75), "Retro Correction (" + round(corAngRet, 1) + ")", 1.0, true).
    set vdPro       to vecDraw(ship:position, proXcl, rgb(1, 0, 0.25), "Prograde", 1.0, true).
    set vdWp        to vecDraw(ship:position, wpXcl, rgb(0.25, 0.55, 1), "Waypoint (" + round(errAng, 1) + ")", 1.0, true).

    print "HORIZONTAL VEC DATA - PRESS 0 FOR VERTICAL" at (2, 15).
    print "------------------------------------------" at (2, 16).
    print "Error Angle          : " + round(errAng, 1) + "    " at (2, 17).
    print "Correction Angle     : " + round(corAng, 1) + "    " at (2, 18).
    print "Retro Correction     : " + round(corAngRet, 1) + "    " at (2, 19).
    
    print "Total Distance       : " + round(wpDist) + "          " at (2, 21).
    print "Positional Distance  : " + round(wpPosMag) + "          " at (2, 22).
    print "Lateral Distance     : " + round(wpLatMag) + "          " at (2, 23).

    wait 0.25.
}
clearVecDraws().

unlock wpXcl.
unlock proXcl.
unlock errAng.
unlock errAngRet.
unlock corAng.
unlock corAngAxis.
unlock corAngRet.

unlock corVec.
unlock corVecAxis.
unlock corVecRet.
unlock wpLatMag.
unlock wpDist.
unlock wpPosMag.

clearScreen.

disp_main(scriptPath()).
disp_msg().


local avgDist       to 0.
local closingDist   to 0.
local closingTime   to 0.
local curAcc        to 0.
local errAng        to 0.
local lastDist      to 0.
local wpDist        to 0.


disp_msg("Vertical mode - Press 0 to end").
local aList to list().
local dList to list().
local eList to list().
list engines in eList.
local ts to time:seconds + 0.25.
ag10 off.
until ag10
{
    set sVal to ship:prograde.

    if ves_engines_on()
    {
        set curAcc to ves_active_thrust(eList) / ship:mass.
    }
    else
    {
        set curAcc to 0.
    }

    set closingDist to lastDist - wp:geoposition:distance.
    set lastDist to wp:geoposition:distance.
    
    dList:add(closingDist).
    if dList:length > 10 
    {
        dList:remove(0).
    }

    if time:seconds > ts 
    {
        local dt to 0. 
        for d in dList {
            set dt to d + dt.
        }
        aList:add(dt).
        if aList:length > 10
        {
            aList:remove(0).
        }

        local avg to 0.
        for val in aList 
        {
            set avg to avg + val.
        }
        set avgDist to (avg / aList:length) * 4.
        set ts to time:seconds + 0.25.
    }

    set closingTime to wp:geoposition:distance / (ship:velocity:surface:mag + curAcc).
    set errAng to vAng(ship:prograde:vector, wp:position).
    set wpDist to wp:geoposition:distance.

    set vdPro       to vecDraw(ship:position, ship:prograde:vector * 10, rgb(1, 0, 0.25), "Prograde", 1.0, true).
    set vdWp        to vecDraw(ship:position, wp:position, rgb(0.25, 0.55, 1), "Waypoint (" + round(errAng, 1) + ")", 1.0, true).

    print "VERTICAL VEC DATA" at (2, 15).
    print "------------------------------------------" at (2, 16).
    print "Error Angle          : " + round(errAng, 5) + "    " at (2, 17).
    //print "Correction Angle     : " + round(corAng, 1) + "    " at (2, 18).
    //print "Retro Correction     : " + round(corAngRet, 1) + "    " at (2, 19).
    
    print "Total Distance       : " + round(wpDist) + "          " at (2, 21).
    print "Average Closing Dist : " + round(avgDist) + "          " at (2, 22).
    print "Closing Time         : " + round(closingTime) + "          " at (2, 23).
}
clearVecDraws().
unlock steering.