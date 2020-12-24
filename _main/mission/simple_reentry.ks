@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_reentry").

clearScreen.

local runmode to 0.

until runmode = 99 {
    
    if runmode  = 0 {
        set runmode to set_rm(5).
    }
    
    else if runmode = 5 {
        if ship:periapsis >= 70000 {
            set runmode to set_rm(10).
        } else {
            set runmode to set_rm(20).
        }
    }
    
    else if runmode = 10 {
        do_kerbin_reentry_burn().
        set runmode to set_rm(20).
    }

    else if runmode = 20 {
        do_kerbin_reentry().
        set runmode to set_rm(99).
    }
}