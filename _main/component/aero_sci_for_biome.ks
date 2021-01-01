@lazyGlobal off. 

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to 0.

local biome is "".
local biomeList to list().

local sciMod is get_sci_mod_for_parts(ship:parts).

local usSciFlag to false.
local usSciMod is get_us_mod().
if usSciMod:length > 0 set usSciFlag to true.

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        set runmode to 2.
    }

    else if runmode = 1 {
        if alt:radar > 25 {
            set runmode to 2.
        }
    }

    else if runmode = 2 {
        set biome to addons:scansat:currentBiome.
        log_sci_list(sciMod).
        //log_us_sci_list(usSciMod).

        PRINT "log_sci_list success" at (2, 8).


        recover_sci_list(sciMod).
        //recover_sci_list(usSciMod).

        PRINT "recover_sci_list success" at (2, 8).

        reset_sci_list(sciMod).
        //reset_sci_list(usSciMod).

        PRINT "reset_sci_list success" at (2, 8).

        biomeList:add(biome).

        clearScreen.
        print "Current Biome: " + biome at (2, 10).
        print "Last science recovered from biome: " + biome at (2, 11).
        print "Current list of researched biomes:" at (2, 15).
        local ln to 16. 
        for b in biomeList {
            print "- " + b at (4, ln).
            set ln to ln + 1.
        }
        
        set runmode to 4.
    }

    else if runmode = 4 {
        if biome <> addons:scansat:currentbiome {
            print "Current Biome: " + biome + "                " at (2, 10).
            if not biomeList:join(";"):contains(addons:scanSat:currentbiome) {
                kuniverse:timewarp:cancelwarp().
                set runmode to 1.
            }
        }
    }

    wait 1.

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

//** End Main
//
