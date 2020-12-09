@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0,
          tgtInc is 82.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_sci_next").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

update_display().
wait 5.

local tgtAltAp is 225000.
local tgtAltPe is 225000.

local mnvObj is lex().
local mnvNode is 0.
local tgtObt is 0.

local sVal is lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
    //Make sure dish is deployed
    if runmode = 0 {
        local dish is ship:partsTaggedPattern("comm.dish").
        for d in dish {
            activate_dish(d).
            logStr("Comm object Dish activated").
            wait 1.
            set_dish_target(d, kerbin:name).
            logStr("Dish target: " + kerbin:name).
        }
        set runmode to 2.
    }


    //Make sure target is set
    else if runmode = 2 {
        set target to Body(tgt).
        set runmode to 4.
    }


    //Prep transfer object and node
    else if runmode = 4 {
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
        set mnvObj to get_transfer_obj().
        set runmode to 6.
    }

    else if runmode = 6 {
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
        set mnvObj to add_transfer_node(mnvObj, tgtAltAp).
        set mnvNode to mnvObj["mnv"].
        set runmode to 8.
    }


    //Execute Transfer
    else if runmode = 8 {
        set sVal to lookDirUp(mnvNode:burnvector, sun:position) + r(0, 0, rVal).
        warp_to_burn_node(mnvObj).
        set runmode to 10.
    }

    else if runmode = 10 {
        set sVal to lookDirUp(mnvNode:burnvector, sun:position) + r(0, 0, rVal).
        exec_node(mnvNode).
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
        set runmode to 12.
    }


    //Warp to the next sphere of influence
    else if runmode = 12 {
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
        warp_to_next_soi().
        set target to "".
        until ship:body:name = tgt {
            update_display().
        }
        set runmode to 14.
    }


    //Circularize, step 1 (initial)
    else if runmode = 14 {
        set mnvNode to add_simple_circ_node("pe", tgtAltAp).
        set mnvObj to get_burn_obj_from_node(mnvNode).
        set runmode to 16.
    }

    else if runmode = 16 {
        warp_to_burn_node(mnvObj).
        set runmode to 18.
    }

    else if runmode = 18 {
        exec_node(mnvNode).
        set runmode to 20.
    }

    //Change inclination
    else if runmode = 20 {

        //Create a new orbit to compare 
        set tgtObt to createOrbit(
            tgtInc, 
            ship:obt:eccentricity, 
            ship:obt:lan, 
            ship:obt:semimajoraxis, 
            ship:obt:argumentofperiapsis, 
            ship:obt:meanAnomalyAtEpoch, 
            ship:obt:epoch, 
            ship:obt:body
            ).

        set mnvNode to get_inc_match_burn(ship, tgtObt)[2].
        add mnvNode.
        set mnvObj to get_burn_obj_from_node(mnvNode).

        set runmode  to 22.
    }

    else if runmode = 22 {
        warp_to_burn_node(mnvObj).
        set runmode to 24.
    }

    else if runmode = 24 {
        exec_node(mnvNode).
        set runmode to 26.
    }

    //Circularize, step 2 (Correction)
    else if runmode = 26 {
        set mnvNode to add_simple_circ_node("ap", tgtAltPe).
        set mnvObj to get_burn_obj_from_node(mnvNode).
        set runmode to 28.
    }

    else if runmode = 28 {
        warp_to_burn_node(mnvObj).
        set runmode to 30.
    }

    else if runmode = 30 {
        exec_node(mnvNode).
        set runmode to 32.
    }

    //Finish script
    else if runmode = 32 {
        logStr("Transfer maneuvers completed, ready for Mission_S2").
        unlock steering.
        unlock throttle.
        
        set runmode to 99.
    }
        

    if ship:availableThrust < 0.1 and tVal > 0 {
        logStr("Staging").
        safe_stage().
    }

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}