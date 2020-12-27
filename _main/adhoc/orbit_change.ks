@lazyGlobal off.

parameter tgtAlt0,
          tgtAlt1,
          flipPhase is false,
          runmodeReset is false.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_mnv").

set stateObj to init_state_obj("ADHOC").
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.
if runmodeReset set runmode to 0.

disp_main().

local sVal is lookDirUp(ship:facing:forevector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then {
    safe_stage().
    preserve.
}

main().

//Main
local function main {

    local nodeAt to 0.


    until runmode = 99 {

        // 
        if runmode = 0 {
            set runmode to 5.
        }

        // Executes the intial hohmann burn node 
        // at the desired point
        else if runmode = 5 {
            set nodeAt to choose "ap" if flipPhase else "pe".
            exec_circ_burn(nodeAt, tgtAlt0).
            set runmode to 10.
        }

        // Executes the second hohman burn.
        else if runmode = 10 {
            set nodeAt to choose "pe" if flipPhase else "ap".
            exec_circ_burn(nodeAt, tgtAlt1).
            set runmode to 45.
        }

        // Preps the vessel for long-term orbit
        else if runmode = 45 {
            end_main().
            set runmode to 99.
        }

        // Logs the runmode change and writes to disk 
        // in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


// Functions
local function end_main {
    set sVal to lookDirUp(ship:facing:forevector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Orbital change completed").
}
