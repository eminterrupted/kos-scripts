@lazyGlobal off.
clearScreen.

wait until ship:unpacked.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

local commsList to ship:partstaggedpattern("groundAntenna").

disp_msg("Waiting for touchdown").
until alt:radar <= 2
{
    disp_telemetry().
}

disp_msg("Tango Delta").
wait 5. 

for a in commsList 
{
    util_do_event(a:getModule("ModuleRTAntenna"), "activate").
}

brakes on.
set core:bootFileName to "".
disp_msg("Rover ready for operations").