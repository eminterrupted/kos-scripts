@lazyGlobal off.

parameter _tgtAp    is 200000,
          _tgtPe    is 200000,
          _tgtInc   is 0,
          _tgtLAN   is 0,
          _tgtArgPe is 0,
          _mnvAcc   is 0.0025. 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

local incPath is "local:/inc_change". 
copyPath("0:/a/simple_inclination_change", incPath).

local obtPath is "local:/obt_change".
copyPath("0:/a/simple_orbit_change", obtPath).

when stage:number <= 0 then {
    panels on.
    for p in ship:partsTaggedPattern("comm") {
        activate_antenna(p).
    }
}


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
runpath(obtPath, _tgtAp, _tgtPe, _tgtArgPe, _mnvAcc).

out_msg("change_orbit.ks complete!").
out_info().