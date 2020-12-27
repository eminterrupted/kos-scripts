@lazyGlobal off.

parameter _rvTgt is "".

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").

set_rm(0).

main().

local function main {
    match_orbit(_rvTgt:orbit).
}

global function match_orbit {
    parameter _tObt.
    
    if not check_argpe(_tObt:argumentOfPeriapsis, 5) {
        change_orbit_argpe(_tObt:argmument).
    }
    
    if not check_ap(_tObt:apoapsis, 5000) or
       not check_pe(_tObt:periapsis, 5000) {
        change_orbit(_tObt:apoapsis, _tObt:periapsis).
    }

}

global function change_orbit_argpe {
    parameter _tArgPe.


    


    return true.
}

global function change_orbit {
    parameter _tAp,
              _tPe.

    return true.
}