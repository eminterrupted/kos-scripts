// Sets up global variables for use in all libraries
@lazyGlobal off.

//Global variables
global errLvl to 0.
global errObj to lexicon().


runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").

global stateObj to init_state_obj().
init_log().

global function init_disk {
    set ship:rootPart:getModule("kosProcessor"):volume:name to "local".
    local disks is list().
    list volumes in disks.
    local di is disks:iterator.
    local idx is 0.

    until not di:next {
        if di:value:name = "" and di:index <= 2 set di:value:name to "log".
        else if di:value:name = "" {
            set di:value:name to "data_" + idx.
            set idx to idx + 1.
        }
    }

    local dLex is lex().
    list volumes in disks.
    for d in disks {
        dLex:add(d:name, d).
    }
    
    return dLex.
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

global function log_state {
    parameter sObj.
    local statePath to "local:/state.json".
    writeJson(sObj, statePath).
}


global function init_state_obj {
    parameter program is 0.
    
    local runmode to 0.
    local sObj is lex().
    local statePath to "local:/state.json".
    
    if exists(statePath) {
        set sObj to readJson(statePath).
        set runmode to choose sObj["runmode"] if sObj:hasKey("runmode") else 0.
        set program to choose sObj["program"] if sObj:hasKey("program") else 0.
    }

    else {
        set runmode to 0.
        set program to 0.
    }

    set sObj to lex("runmode", runmode, "program", program).
    log_state(sObj).

    return sObj.
}

global function set_runmode {
    parameter rm.
    
    set stateObj["runmode"] to rm.
    log_state(stateObj).
}
