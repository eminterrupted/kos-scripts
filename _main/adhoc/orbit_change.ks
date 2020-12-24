@lazyGlobal off.

parameter tgtAlt0,
          tgtAlt1,
          runmodeReset is false,
          flipPhase is false.

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
runOncePath("0:/lib/nav/lib_circ_burn").

set stateObj to init_state_obj("ADHOC").
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.
if runmodeReset set runmode to 0.

disp_main().

local mnvNode is 0.
local mnvObj is lex().

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
    until runmode = 99 {

        //Get the list of science experiments
        if runmode = 0 {
            set runmode to 5.
        }

        //Adds the intial hohmann burn node 
        //to the flight plan at the desired point
        else if runmode = 5 {
            local nodeAt to choose "ap" if flipPhase else "pe".
            set mnvNode to add_simple_circ_node(nodeAt, tgtAlt0).
            set runmode to 10.
        }

        //Gets the burn info from the node
        else if runmode = 10 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 15.
        }

        //Warps to the burn node
        else if runmode = 15 {
            warp_to_burn_node(mnvObj).
            set runmode to 20.
        }

        //Executes the burn node
        else if runmode = 20 {
            exec_node(nextNode).
            set runmode to 25.
        }

        //Adds a circularization node to the flight plan
        else if runmode = 25 {
            local nodeAt to choose "pe" if flipPhase else "ap".
            set mnvNode to add_simple_circ_node(nodeAt, tgtAlt1).
            set runmode to 30.
        }

        //Gets burn data from the node
        else if runmode = 30 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 35.
        }

        //Warps to the burn node
        else if runmode = 35 {
            warp_to_burn_node(mnvObj).
            set runmode to 40.
        }

        //Executes the circ burn
        else if runmode = 40 {
            exec_node(nextNode).
            wait 2.
            set runmode to 45.
        }

        //Preps the vessel for long-term orbit
        else if runmode = 45 {
            end_main().
            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


//Functions
local function end_main {
    set sVal to lookDirUp(ship:facing:forevector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Orbital change completed").
}
