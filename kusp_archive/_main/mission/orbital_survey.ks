@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_antenna").
runOncePath("0:/lib/lib_solar").

local sciList to get_sci_mod().
local tStamp is 0.

// -- Main -- //

update_display().

lock steering to lookDirUp(ship:prograde:vector, sun:position).
wait until shipSettled().

out_msg("Deploying satellite").
until stage:number <= 0 {
    safe_stage().
}

set tStamp to time:seconds + 10.

// Run the faux "boot" sequence
out_msg("Initiating boot sequence").
until time:seconds >= tStamp {
    update_display().
    disp_block(list("bootTimer", "Boot Timer", "mark", round(tStamp - time:seconds))).
    
    if tStamp - time:seconds <= 1 {
        for p in ship:partsTaggedPattern("comm.omni") {
            activate_antenna(p).
        }
    }

    else if tStamp - time:seconds <= 4 {
        for p in ship:partsTaggedPattern("comm.dish") {
            activate_antenna(p).
        }
    }

    else if tStamp - time:seconds <= 7 {
        panels on.
    }

    wait 1.
}

disp_clear_block("bootTimer").
out_msg("Boot sequence complete!").

wait 2.

out_msg("Commencing orbital survey").
    
lock steering to lookDirUp(ves_srf_normal(), sun:position).

// Setup the science trigger
when ship:altitude < info:altForSci[ship:body] then {
    log_sci_list(sciList).
    recover_sci_list(sciList, true).
}

when ship:altitude > info:altForSci[ship:body] then {
    log_sci_list(sciList).
    recover_sci_list(sciList, true).
}

until false {
    update_display().
}