@lazyGlobal off.

parameter _tgtInclination,
          _tgtLongitudeAscendingNode is ship:orbit:lan.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_node").
runOncePath("0:/lib/lib_mnv").

local runmode to 0.

disp_main().

// Creating the new orbit
local targetObt is createOrbit(
    _tgtInclination, 
    ship:orbit:eccentricity, 
    ship:orbit:semiMajorAxis, 
    _tgtLongitudeAscendingNode,
    ship:orbit:argumentOfPeriapsis,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    ship:body).

// Inclination match burn data
local burn to "".
local utime to 0.
local burnVector to v(0, 0, 0).
local leadTime to 0.

//Maneuver node structures
local mnvNode is node(0, 0, 0, 0).

//Steering
local rVal is 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then 
{
    safe_stage().
    preserve.
}

main().
end_main().

//Main
local function main 
{
    until runmode = 99 
    {

        if runmode = 0 
        {
            out_msg("Executing simple_inclination_change.ks").
            out_info("Target: " + _tgtInclination + "   Current: " + round(ship:obt:inclination, 5)).
            set runmode to 2.
        }
        
        // Add the burn node after getting the data
        else if runmode = 2 
        {
            set burn to get_inc_match_burn(ship, targetObt).
            set utime to burn[0].
            set burnVector to burn[1].
            set leadTime to utime - get_burn_dur(burnVector:mag / 2).
            set mnvNode to burn[2].
            add mnvNode.

            set runmode to 5.
        }

        // Do burn
        else if runmode = 5 
        {
            
            set sVal to lookDirUp(nextNode:burnVector, sun:position).
            wait until shipSettled().

            warpTo(leadTime - 30).

            // Wait until we get to the burn
            until time:seconds >= leadTime  - 15 
            {
                set sVal to lookDirUp(nextNode:burnVector, sun:position).
                update_display().
                disp_burn_data(leadtime).
                wait 0.1. 
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().

            until time:seconds >= leadTime 
            {
                set sVal to lookDirUp(nextNode:burnVector, sun:position).
                update_display().
                disp_burn_data(leadTime).
                wait 0.01.
            }

            set runmode to 7.
        }

        else if runmode = 7 
        {

            //Do the burn.
            exec_node(mnvNode).
            disp_clear_block("burn_data").
            
            set runmode to 10.
        }

        else if runmode = 10 
        {

            set runmode to 99.
        }

        update_display().
    }
}


//Functions
local function end_main 
{
    unlock steering.
    unlock throttle.
    clearScreen.
}