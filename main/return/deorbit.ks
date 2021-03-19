@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).
disp_msg("Executing deorbit burn").
lock steering to ship:retrograde.
until ves_settled()
{   
    disp_orbit().
}

wait until ves_settled().

lock throttle to 1.
until ship:periapsis < 0 
{
    disp_orbit().
}
lock throttle to 0.
unlock steering.
disp_msg("Deorbit burn completed").

until false
{
    disp_orbit().
}