// Sets up global variables for use in all libraries
@lazyGlobal off.

global errLvl is 0.
global errObj is lexicon().
global stateObj is lexicon().

local statePath is "1:/state.json".

runOncePath("0:/lib/lib_log.ks").
runOncePath("0:/lib/lib_tag.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/maneuver/lib_nav.ks").

init_err().
init_state_obj().

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


global function init_program {
    if defined program unset program. 
    global program is 0.
    set stateObj["program"] to program.
}


global function init_runmode {
    if defined runmode unset runmode.
    global runmode is 0.
    set stateObj["runmode"] to runmode.
}


global function log_state {
    writeJson(stateObj, statePath).
}


global function init_state_obj {
    if exists(statePath) {
        set stateObj to readJson(statePath).
    }

    else {
        init_runmode().
        init_program().
        log_state().
    }
}