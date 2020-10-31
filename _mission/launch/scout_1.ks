@lazyGlobal off. 

parameter tApo is 125000,
          tPe is 125000,
          tInc is 0,
          gravTurnAlt is 60000,
          refPitch to 3.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_launch.ks").

//
//** Main

//Vars
local maxAlt is 0.
local runmode is 0.

//Get a list of science parts

until runmode = 5 {
    
    //Setup
    local sciList is get_sci_list(ship:parts).

    //pad science
    if runmode = 0 {   
        log_sci_list(sciList).
        set runmode to 1.
    }

    //countdown
    else if runmode = 1 {
        launch_vessel().
        set runmode to 2.
    }

    //launch
    else if runmode = 2 and alt:radar >= 250 {
        log_sci_list(sciList).
        set runmode to 3.
    }

    else if runmode = 3 {
        when alt:radar >= 18000 then {
            log_sci_list(sciList).
        } 
        set runmode to 4.
    }

    else if runmode = 4 {
        if alt:radar <= 50 set runmode to 5.
    }

    set maxAlt to max(maxAlt, ship:altitude).

    update_display(runmode, maxAlt).

    wait 0.001.
}

//** End Main
//
