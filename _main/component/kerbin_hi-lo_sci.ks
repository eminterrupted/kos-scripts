@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").


runOncePath("0:/lib/data/ship/lib_mass").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

local sciList to get_sci_mod_for_parts(ship:parts).

lock steering to lookdirup(ship:facing:forevector, sun:position) + r(0, 0, rVal).

clearscreen.

until runmode = 99 {
   
   //Do one pass of always-transmit sci for contracts
    if runmode = 0 {
       if ship:altitude >= 250000 {
           safe_stage().
           set runmode to 5.
       }
    }

    else if runmode = 5 {
        log_sci_list(sciList).
        recover_sci_list(sciList, true).

        set runmode to 10.
    }

    else if runmode = 10 {
        if ship:altitude < 250000 set runmode  to 15.
    }

    else if runmode = 15 {
        log_sci_list(sciList).
        recover_sci_list(sciList, true).
        set runmode to 20.
    }

    //Now set up triggers to always check sci and transmit if val > 0 (so alwaysTransmit = false)
    else if runmode = 20 {
        when ship:altitude >= 250000 then {
            log_sci_list(sciList).
            recover_sci_list(sciList).
            preserve.
        }

        when ship:altitude < 250000 then {
            log_sci_list(sciList).
            recover_sci_list(sciList).
            preserve.
        }   

        set runmode to 30.
    }

    update_display().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

//** End Main
//
