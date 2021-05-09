@lazyGlobal off.
clearScreen.

parameter tgtParam is ship:orbit:nextPatch:body.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_nav").

local tgtBody to tgtParam.

if tgtParam:typename = "list"
{
    set tgtBody to nav_orbitable(tgtParam[0]).
}
else if tgtParam:typeName = "string"
{
    set tgtBody to nav_orbitable(tgtParam).
}

disp_main(scriptPath()).

local rVal to 0.

lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).

util_warp_trigger(time:seconds + ship:orbit:nextpatcheta).

until ship:body:name = tgtBody:name
{
    disp_info2("Time to SOI change: " + round(ship:orbit:nextpatcheta)).
    disp_orbit().
    wait 0.1.
}

disp_info2().
disp_info2("Arrived at " + tgtBody:name + " SOI").