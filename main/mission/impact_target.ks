@lazyGlobal off.
clearScreen.

parameter tgtWaypoint to "Active".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

if tgtWaypoint = "Active" 
{
    for wp in allWaypoints()
    {
        if wp:isselected set tgtWaypoint to wp.
    }
}
else if tgtWaypoint:typename = "string" 
{
    for wp in allWaypoints() 
    {
        if wp:name = tgtWaypoint set tgtWaypoint to wp.
    }
} 
else if tgtWaypoint:typename <> "Waypoint"
{
    disp_msg("ERR: [" + tgtWaypoint + "] Not a known waypoint").
    disp_hud("ERR: [" + tgtWaypoint + "] Not a known waypoint", 2).
    print 1 / 0.
}

local sciMods to sci_modules().
local tti to 0.
local tVal to 0.

lock throttle to tVal.

// Locks
// Replaces the buggy built-in alt:radar
lock altRadar to ship:altitude - ship:geoPosition:terrainheight.

// This gets the angle between the ship's lateral prograde vector and 
// the target's lateral position vector
lock wpLatVec to vxcl(body:position, tgtWaypoint:position):normalized.
lock proLatVec to vxcl(body:position, ship:prograde:vector):normalized.

// This gets the lateral distance to the target (removes altitude component)
lock tgtLatDist to wpLatVec:mag.

// This returns the lateral angle between prograde and target position
lock tgtLatAng to vAng(wpLatVec, proLatVec).



if not addons:tr:hasImpact
{
    lock steerVec to ship:retrograde:vector - tgtVector.
    lock steering to steerVec.

    local vdraw to vecDraw(ship:position, steerVec, rgb(1, 0, 0), "TgtVector",1.0, true).

    until false 
    {
        vdraw:vecupdater.
    }

    wait 25.
}

until altRadar <= 25000
{
    set tti to land_time_to_impact(ship:verticalspeed, altRadar).
    disp_impact(tti).
}












// set tVal to 1.
// until stage:number = 0 
// {
//     stage.
//     wait 0.25.
// }

// until tti <= 10
// {
//     set tti to land_time_to_impact(ship:verticalspeed, altRadar).
//     disp_impact(tti).
// }

// sci_deploy_list(sciMods).
// sci_recover_list(sciMods, "transmit").

// until false
// {
//     set tti to land_time_to_impact(ship:verticalspeed, altRadar).
//     disp_impact(tti).
// }