@lazyGlobal off.

parameter _tgtAp    is 2500000,
          _tgtPe    is 225000,
          _tgtInc   is 22,
          _tgtLAN   is ship:orbit:longitudeofascendingnode,
          _tgtArgPe is 270.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

local incPath is "local:/incChange". 
copyPath("0:/_adhoc/simple_inclination_change", incPath).

local argPePath is "local:/argPeChange".
copyPath("0:/_adhoc/simple_arg_pe_change", argPePath).


//-- Main --//
// Inclination check and change
out_msg("Checking inclination parameters").

// _tgtInc and _tgtLAN check
if not check_value(ship:orbit:inclination, _tgtInc, 2.5) or not check_value(ship:orbit:lan, _tgtLAN, 15) {
    out_msg("Inclination not within parameters").
    runpath(incPath, _tgtInc, _tgtLAN).
}

// Run the orbit boost script
out_msg("Executing orbit change at desired argPe").
out_info("tgtAp: " + _tgtAp + "   tgtPe: " + _tgtPe + "   tgtArgPe: " + _tgtArgPe).
runpath(argPePath, _tgtArgPe, _tgtAp, _tgtPe).

out_msg("change_orbit.ks complete!").
out_info().