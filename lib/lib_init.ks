// Sets up global variables for use in all libraries
@lazyGlobal off.

//Global variables
global errLvl to 0.
global errObj to lexicon().
global sun is Body("Sun").

runOncePath("0:/lib/lib_tag").
runOncePath("0:/lib/lib_log").

global stateObj to init_state_obj().

global function init_disk {
    
    local disks is list().

    local diskIdx to 1.
    local logDisk to "".
    local logDiskIdx to 0.
    local logSize is 999999.

    // Get all the disks from the vessel
    for cpu in ship:modulesNamed("kOSProcessor") {
        if cpu:part:uid = core:part:uid {
            set core:volume:name to "local".

        } else if not cpu:volume:name:contains("local") {
            if cpu:volume:capacity < logSize {
                if logDisk:isType("Volume") {
                    set logDisk:name to "data_" + logDiskIdx.
                }

                set cpu:volume:name to "log".

                set logDisk to cpu:volume.
                set logDiskIdx to diskIdx. 
                set logSize to logDisk:capacity.
            } else {
                set cpu:volume:name to "data_" + diskIdx.
            }

        }
        
        set diskIdx to diskIdx + 1.
    }

    // local di is disks:iterator.
    // local idx to 0.
    // local logDisk to "".
    // local logDiskIdx to 0.
    // local logSize is 999999.
    
    // //Set smallest remaining disk as log disk
    // until not di:next {
    //     if di:value:name <> "local" and di:value:name <> "Archive" {
    //         if di:value:capacity < logSize {

    //             if logDisk:isType("Volume") {
    //                 set logDisk:name to "data_" + logDiskIdx.
    //             }

    //             set di:value:name to "log".
    //             set logDisk to di:value.
    //             set logDiskIdx to di:index - 1.
    //             set logSize to di:value:capacity.
    //         }
    //     }
        
    //     set idx to idx + 1.
    // }

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
    local subroutine is "".
    local sObj is lex().
    local statePath to "local:/state.json".
    
    if exists(statePath) {
        set sObj to readJson(statePath).
        set program to choose sObj["program"] if sObj:hasKey("program") else 0.
        set runmode to choose sObj["runmode"] if sObj:hasKey("runmode") else 0.
        set subroutine to choose sObj["subroutine"] if sObj:hasKey("subroutine") else "".
    }

    else {
        set runmode to 0.
        set program to 0.
        set subroutine to "".
    }

    set sObj to lex("runmode", runmode, "program", program, "subroutine", subroutine).
    log_state(sObj).

    return sObj.
}

global function set_rm {
    parameter runmode.

    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


global function init_subroutine {
    local subroutine to choose 0 if stateObj["subroutine"] = "" else stateObj["subroutine"].
    return subroutine.
}

global function set_sr {
    parameter subroutine.
    
    set stateObj["subroutine"] to subroutine.
    log_state(stateObj).

    return subroutine.
}