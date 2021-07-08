@lazyGlobal off.
clearscreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath(), false).

local panelList to list().
local commList  to list().

local ts to time:seconds + 10.

until time:seconds >= ts 
{
    print "TIME TO LIFTOFF: " + disp_format_time(ts - time:seconds) at (2, 10).
}

stage.

wait 15.

set commList to ship:modulesNamed("ModuleRTAntenna").
set panelList to ship:modulesNamed("ModuleDeployableSolarPanel").

ves_activate_antenna(commList, true).
ves_activate_solar(panelList, true).