// Sets up global variables for use in all libraries
@lazyGlobal off.

global errLvl to 0.
global errObj to lexicon().

runOncePath("0:/lib/lib_log.ks").
runOncePath("0:/lib/lib_tag.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/nav/lib_nav.ks").

local statePath to "local:/state.json".
init_state_obj().

global function init_disk {
    
    local disks to list().
    list volumes in disks.
    local idx to 0.

    for v in disks {
        if idx = 1 {
            set v:name to "Local".
        }

        else if idx = 2 {
            set v:name to "log".
        }

        else if idx > 2 {
            set v:name to choose "data_" + idx:tostring if v:name = "" else "data_" + v:name.
        }

        set idx to idx + 1.
    }

    list volumes in disks.
    return disks.
}


global function init_err {
    set errLvl to 0.
    set errObj to lexicon().
}


global function init_errLvl {
    set errLvl to 0.
    return errLvl.
}


global function init_errObj {
    set errObj to lexicon().
    return errObj.
}

// global function get_state_obj {
//     set stateObj to readJson(statePath).
//     return stateObj.
// }

global function log_state {
    parameter stateObj.
    writeJson(stateObj, statePath).
}


global function init_state_obj {
    local program to 0.
    local runmode to 0.
    local stateObj is lex().
    
    if exists(statePath) {
        set stateObj to readJson(statePath).
        set runmode to choose stateObj["runmode"] if stateObj:hasKey("runmode") else 0.
        set program to choose stateObj["program"] if stateObj:hasKey("program") else 0.
    }

    else {
        set runmode to 0.
        set program to 0.
    }

    set stateObj to lex("runmode", runmode, "program", program).
    log_state(stateObj).
    return stateObj.
}