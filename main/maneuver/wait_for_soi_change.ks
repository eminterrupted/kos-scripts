@lazyGlobal off.
clearScreen.

parameter tgtParam is choose target if hasTarget else ship:orbit:nextpatch:body.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath()).

local orientation to "prograde".
local tgtBody to tgtParam.

if tgtParam:typename = "list"
{
    set tgtBody to nav_orbitable(tgtParam[0]).
}
else if tgtParam:typeName = "string"
{
    set tgtBody to nav_orbitable(tgtParam).
}

if util_peek_cache("soiDestination")
{
    set tgtBody to util_read_cache("soiDestination").
}
else
{
    util_cache_state("soiDestination", tgtBody).
}

local rVal to 0.
if orientation = "retrograde"
{
    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, rVal).
}
else if orientation = "sun_facing"
{
    lock steering to lookDirUp(sun:position, tgtBody:position) + r(0, 0, rVal).
}
else
{
    lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
}

if ship:body:name <> tgtBody:name 
{
    util_warp_trigger(time:seconds + ship:orbit:nextpatcheta, "SOI change").
}

until ship:body:name = tgtBody:name
{
    disp_msg("Time to SOI change: " + disp_format_time(ship:orbit:nextpatcheta, "ts")).
    disp_orbit().
    wait 0.01.
}

disp_msg().
disp_msg("Arrived at " + tgtBody:name + " SOI").
util_clear_cache_key("soiDestination").