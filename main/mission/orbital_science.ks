@lazyGlobal off.
clearScreen.

parameter recoveryMode is "ideal".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Flags
local recover       to true.

// Variables
local bayList      to ves_get_us_bays().
local validModes   to list("transmit", "ideal", "collect").
local sciList       to sci_modules().

lock steering to lookDirUp(ship:prograde:vector, sun:position).

disp_main(scriptPath():name).
disp_orbit().

ves_open_bays(bayList).
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

if recover 
{
    sci_recover_list(sciList, recoveryMode).
}

disp_msg("Orbital science complete!").
wait 1.
disp_msg("Manual science mode, press 0 to collect data").

ag10 off.
when ag10 then 
{
    disp_msg("Manual data collection in progress").
    sci_deploy_list(sciList).
    sci_recover_list(sciList, recoveryMode).
    disp_msg("Manual science mode, press 0 to collect data").
    ag10 off.
    preserve.
}

until false 
{
    disp_orbit().
    wait 0.01.
}