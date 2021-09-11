@lazyGlobal off.
clearScreen.

parameter recoveryMode is "ideal".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Flags
local validModes to list("transmit", "ideal", "collect").
local sciList    to sci_modules().
local sciNorth   to false.
local sciSouth   to false.

lock steering to lookDirUp(ship:prograde:vector, sun:position).

disp_main(scriptPath():name).
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
sci_recover_list(sciList, recoveryMode).
if ship:latitude > 0 
{
    set sciNorth to true.
    disp_msg("Recon of northern hemisphere complete").
}
else
{
    set sciSouth to true.
    disp_msg("Recon of southern hemisphere complete").
}

if sciNorth
{
    until ship:latitude < 0
    {
       disp_orbit().
       wait 0.01.
    }
    sci_deploy_list(sciList).
    sci_recover_list(sciList, recoveryMode).
    disp_msg("Recon of southern hemisphere complete").
    set sciSouth to true.
}
else 
{
    until ship:latitude > 0 
    {
        disp_orbit().
        wait 0.01.
    }
    sci_deploy_list(sciList).
    sci_recover_list(sciList, recoveryMode).
    set sciNorth to true.
    disp_msg("Recon of northern hemisphere complete").
}

wait 2.

if sciNorth and sciSouth 
{
    disp_msg("Recon mission complete").
    wait 1.
}