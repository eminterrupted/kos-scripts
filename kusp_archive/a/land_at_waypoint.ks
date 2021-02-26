@lazyGlobal off.

parameter wp. // a waypoint to land at

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_land").

// Format the input param
if wp:isType("string") {
    set wp to waypoint(wp).
}

local targetDistOld to 0.
local wpGeo to wp:geoPosition.

// Pids
local climbPid    to pidLoop(0.4, 0.3, 0.005, 0, 1). // Controls vertical speed
local hoverPid    to pidLoop(1, 0.01, 0.0, -15, 15). // Controls altitude by changing setpoint of climbPid
set hoverPid:setpoint to addons:scansat:elevation(wp:body, wpGeo) + 25.

local eastVelPid  to pidLoop(3, 0.01, 0.0, -35, 35). // Controls horizontal speed by pitching
local northVelPid to pidLoop(3, 0.01, 0.0, -35, 35). // ^
local eastPosPid  to pidLoop(1700, 0, 100, -30, 30). // Controls horizontal position be changing velPid setpoints
local northPosPid to pidLoop(1700, 0, 100, -30, 30). // ^
set eastPosPid:setpoint to wpGeo:lng.
set northPosPid:setpoint to wpGeo:lat.

//TO DO: initial impact burn
lock steering to lookDirUp(ship:retrograde:vector, sun:position).


until addons:tr:hasImpact {
    update_display().
    disp_landing().
}

// Now that we have impact, let's tune the direction
lock targetDist to geo_dist(wpGeo, addons:tr:impactpos).
lock targetDir  to geo_dir(addons:tr:impactpos, wpGeo).