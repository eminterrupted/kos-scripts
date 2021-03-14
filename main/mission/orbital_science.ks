@lazyGlobal off.
clearScreen.

parameter recoveryMode is "ideal".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Flags
local recover       to true.
local validModes  to list("transmit", "ideal", "collect").
local sciList       to sci_modules().

lock steering to lookDirUp(ship:prograde:vector, body("sun"):position).

disp_main().
disp_orbit().

ves_activate_antenna().
ves_activate_solar().

// Validate recover mode
if not validModes:contains(recoveryMode) 
{
    disp_msg("ERROR: [" + recoveryMode + "] not a valid recovery mode").
    wait 5.
    print 1 / 0.
}

sci_deploy_list(sciList).

if recover {
    sci_recover_list(sciList, recoveryMode).
}

disp_msg("Orbital science complete!").
wait 5.