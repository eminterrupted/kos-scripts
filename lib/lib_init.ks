// Sets up global variables for use in all libraries
@lazyGlobal off.

//Global variables
global errLvl   to 0.
global errObj   to lexicon().
global sun      to Body("Sun").
global verbose  to true.

runOncePath("0:/lib/lib_tag").
runOncePath("0:/lib/lib_log").

global stateObj to init_state_obj().

global function init_disk 
{
    
    local cores is list().
    local disks is list().
    local diskIdx to 0.
    local logFlag to false.

    // Get all the cores of the vessel
    for cpu in ship:modulesNamed("kOSProcessor") 
    {
        set cpu:volume:name to "".
        cores:add(cpu).

    }

    set core:volume:name to "local".
    for c in cores
    {
        if c:volume:name <> "local" 
        {
            if not logFlag 
            {
                set c:volume:name to "log".
                set logFlag to true.
            }
            else 
            {
                set c:volume:name to "data_" + diskIdx.
                set diskIdx to diskIdx + 1.
            }
        }
    }

    local dLex is lex().
    list volumes in disks.
    for d in disks {
        dLex:add(d:name, d).
    }
    
    return dLex.
}


global function init_err 
{
    set errLvl to 0.
    set errObj to lexicon().
}


global function init_errLvl 
{
    set errLvl to 0.
    return errLvl.
}


global function init_errObj 
{
    set errObj to lexicon().
    return errObj.
}

global function log_state 
{
    parameter sObj.
    local statePath to "local:/state.json".
    writeJson(sObj, statePath).
}

global function init_state_obj
{
    parameter program is 0.
    
    local runmode to 0.
    local subroutine is "".
    local sObj is lex().
    local statePath to "local:/state.json".
    
    if exists(statePath) 
    {
        set sObj to readJson(statePath).
        set program to choose sObj["program"] if sObj:hasKey("program") else 0.
        set runmode to choose sObj["runmode"] if sObj:hasKey("runmode") else 0.
        set subroutine to choose sObj["subroutine"] if sObj:hasKey("subroutine") else "".
    }
    else 
    {
        set runmode to 0.
        set program to 0.
        set subroutine to "".
    }

    set sObj to lex("runmode", runmode, "program", program, "subroutine", subroutine).
    log_state(sObj).

    return sObj.
}

global function init_rm 
{    
    local runmode to choose 0 if stateObj["runmode"] = 99 else stateObj["runmode"].
    return runmode.
}


global function rm 
{
    parameter runmode is 0.

    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


global function init_subroutine 
{
    local subroutine to choose 0 if stateObj["subroutine"] = "" else stateObj["subroutine"].
    return subroutine.
}

global function sr 
{
    parameter subroutine is "".
     
    set stateObj["subroutine"] to subroutine.
    log_state(stateObj).

    return subroutine.
}