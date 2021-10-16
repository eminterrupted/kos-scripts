@lazyGlobal off.
clearScreen.

parameter tgtPe to ship:body:atm:height / 2.

runOncePath("0:/lib/lib_disp").

disp_main(scriptPath()).

lock steering to ship:retrograde.
until ship:orbit:periapsis <= tgtPe
{
    disp_msg("Aerobrake maneuver in progress").
    disp_orbit().
}

disp_msg("Aerobraking completed").
