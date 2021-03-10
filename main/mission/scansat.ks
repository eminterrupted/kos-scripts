@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_addon_scansat").

local sVal to lookDirUp(ship:prograde:vector, body("sun"):position).
lock steering to sVal.

local scanList      to ship:partsDubbedPattern("scansat").
local scanDelegates to scansat_field_delegates().

local scanStatus    to "".
local scanAlt       to "".
local scanType      to "".
local scanFov       to "".
local scanPower     to "".
local scanDaylight  to "".

local scanner to scanList[0].
scansat_activate(scanner, true).

// print scanDelegates. 

set scanStatus     to scanDelegates:scanStatus@:bind(scanner).
set scanAlt        to scanDelegates:scanAlt@:bind(scanner).
set scanType       to scanDelegates:scanType@:bind(scanner).
set scanFov        to scanDelegates:scanFov@:bind(scanner).
set scanPower      to scanDelegates:scanPower@:bind(scanner).
set scanDaylight   to scanDelegates:scanDaylight@:bind(scanner).

until false {
    print "SCANSAT" at (0, 2).
    print "-------" at (0, 3).
    print "VESSEL     : " + ship:name at (0, 4).
    print " " at (0, 5).
    print "SCANNER    : " + scanner:Title at (0, 6).
    print "SCAN TYPE  : " + scanType() at (0, 7).
    print "ALT RANGE  : " + scanAlt() at (0, 8).
    print " " at (0, 9).
    print "STATUS     : " + scanStatus() + "     " at (0, 10).
    print "SCAN FOV   : " + scanFov() + "   " at (0, 11). 
    print "SCAN POWER : " + scanPower() + "     " at (0, 12).
    print "DAYLIGHT   : " + scanDaylight() + "     " at (0, 13).
    print " " at (0, 14).
    print " " at (0, 15).
    print "COVERAGE" at (0, 16).
    print "--------" at (0, 17).
    print "AltimetryLoRes : " + round(addons:scansat:getCoverage(ship:body, "AltimetryLoRes"), 2) at (0, 18).
    print "AltimetryHiRes : " + round(addons:scansat:getCoverage(ship:body, "AltimetryHiRes"), 2) at (0, 19).
    print "Anomaly        : " + round(addons:scansat:getCoverage(ship:body, "Anomaly"), 2) at (0, 20).
    print "AnomalyDetail  : " + round(addons:scansat:getCoverage(ship:body, "AnomalyDetail"), 2) at (0, 21).
    print "Biome          : " + round(addons:scansat:getCoverage(ship:body, "Biome"), 2) at (0, 22).
    print "ResourceLoRes  : " + round(addons:scansat:getCoverage(ship:body, "ResourceLoRes"), 2) at (0, 23).
    print "ResourceHiRes  : " + round(addons:scansat:getCoverage(ship:body, "ResourceHiRes"), 2) at (0, 24).
    print "VisualLoRes    : " + round(addons:scansat:getCoverage(ship:body, "VisualLoRes"), 2) at (0, 25).
    print "VisualHiRes    : " + round(addons:scansat:getCoverage(ship:body, "VisualHiRes"), 2) at (0, 26).

    wait 0.01.
}