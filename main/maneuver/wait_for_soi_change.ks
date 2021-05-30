@lazyGlobal off.
clearScreen.

parameter tgtParam is choose target if hasTarget else ship:orbit:nextpatch:body.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath()).

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
lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).

if ship:body:name <> tgtBody:name 
{
    util_warp_trigger(time:seconds + ship:orbit:nextpatcheta).
}

until ship:body:name = tgtBody:name
{
    disp_info2("Time to SOI change: " + round(ship:orbit:nextpatcheta)).
    disp_orbit().
    wait 0.1.
}

disp_info2().
disp_info2("Arrived at " + tgtBody:name + " SOI").
util_clear_cache_key("soiDestination").