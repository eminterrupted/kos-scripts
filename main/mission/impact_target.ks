@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

local sciMods to sci_modules().
local tti to 0.
local tVal to 0.

lock altRadar to ship:altitude - ship:geoPosition:terrainheight.
lock steering to lookDirUp(ship:prograde:vector, sun:position).
lock throttle to tVal.


until altRadar <= 25000
{
    set tti to land_time_to_impact(ship:verticalspeed, altRadar).
    disp_impact(tti).
}

set tVal to 1.
until stage:number = 0 
{
    stage.
    wait 0.25.
}

until tti <= 10
{
    set tti to land_time_to_impact(ship:verticalspeed, altRadar).
    disp_impact(tti).
}

sci_deploy_list(sciMods).
sci_recover_list(sciMods, "transmit").

until false
{
    set tti to land_time_to_impact(ship:verticalspeed, altRadar).
    disp_impact(tti).
}