@lazyGlobal off.
clearScreen.

parameter recoveryMode is "ideal".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Flags
local recover    to true.
local validModes to list("transmit", "ideal", "collect").
local sciList    to sci_modules().
local tVal       to 0.

// Validate recover mode
if not validModes:contains(recoveryMode) 
{
    disp_msg("ERROR: [" + recoveryMode + "] not a valid recovery mode").
    wait 1.
    print 1 / 0.
}

disp_main(scriptPath():name).
disp_orbit().

lock steering to lookDirUp(ship:prograde:vector, sun:position).
lock throttle to tVal.

ves_activate_antenna().
ves_activate_solar().

// If we aren't in Sun SOI, check if we are on an escape trajectory. Run burn script if needed
if ship:body <> body("sun") 
{
    if ship:orbit:hasnextpatch
    {
        if ship:orbit:nextPatch:body <> body("sun")
        {
            disp_msg("Currently not on an escape trajectory!").
            runPath("0:/main/maneuver/kerbin_escape").
        }
    }
    else
    {
        disp_msg("Currently not on an escape trajectory!").
        runPath("0:/main/maneuver/kerbin_escape").
    }
}

// Wait until Sun SOI
local tsSOI to time:seconds + ship:orbit:eta:transition.
disp_msg("Waiting until " + body("sun"):name + " SOI").
until ship:body = body("sun") 
{
    disp_info("Time to SOI transition: " + round(time:seconds - tsSOI)).
    disp_orbit().
}

disp_msg("Now in " + body("sun"):name + " SOI       ").

sci_deploy_list(sciList).

if recover {
    sci_recover_list(sciList, recoveryMode).
}

disp_msg("Complete!").
wait 5.