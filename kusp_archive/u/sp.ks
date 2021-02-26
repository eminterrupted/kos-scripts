@lazyGlobal off.

parameter _geoTgt is "wp".

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_nav").

// Check for trajectories, fail if not found
if not addons:tr:available
{
    print 1 / 0. // Trajectories mod not installed
}

// Waypoint
if _geoTgt = "wp" 
{
    set _geoTgt to active_waypoint():geoposition.
}

local tStamp to time:seconds + 3.
local lngStart to ship:geoPosition:lng.
until time:seconds >= tStamp 
{
    update_display().
    disp_timer(tStamp, "Phase Sample").
}
local lngEnd to ship:geoPosition:lng.
local phaseFactor to ABS(lngEnd - lngStart) / 3.

disp_clear_block_all().

local lngTgt to _geoTgt:lng.
local orbitDir to choose true if ship:orbit:inclination <= 90 else false.

out_info("Warping until longitude window").
local burnLng to choose lngTgt + 15 if orbitDir else lngTgt - 15.
local wpEta to time:seconds + abs((burnLng - ship:geoposition:lng) / phaseFactor).
warpTo(wpEta - 15).
until time:seconds >= wpEta 
{    
    set wpEta to time:seconds + abs((burnLng - ship:geoposition:lng) / phaseFactor).
    update_display().
    disp_tel().
    disp_timer(wpEta, "WINDOW ETA").
    wait 0.01.
}

out_info().
disp_clear_block_all().

out_info("Burning until impact detected").
lock steering to ship:srfretrograde.
wait 2.5.
wait until shipSettled().

until addons:tr:hasimpact 
{
    lock throttle to 1.
    update_display().
    disp_tel().
    wait 0.01.
}
lock throttle to 0.
out_info().
wait 5.

lock impactLng to addons:tr:impactPos:lng.

out_info("Burning at 75% to impact position +- 2.5").
until check_lng_window(impactLng, lngTgt, 2.5) 
{
    lock throttle to 0.75.
    update_display().
    disp_tel().
    wait 0.01.
}

out_info("Burning at 25% to impact position +- 0.1").
until check_lng_window(impactLng, lngTgt, 0.1)
{
    lock throttle to 0.25.
    update_display().
    disp_tel().
    wait 0.01.
}
lock throttle to 0.
clearScreen.

//-- Functions --//

local function check_lng_window 
{
    parameter _lng0, _lng1, _factor.
    
    if orbitDir 
    {
        if _lng0 >= _lng1 - _factor and _lng0 <= _lng1 + _factor
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
    else 
    {
        if _lng0 >= _lng1 + _factor and _lng0 <= _lng1 - _factor
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
}
