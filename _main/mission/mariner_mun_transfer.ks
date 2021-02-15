@lazyGlobal off.

parameter tgtBody   is "Mun",
          tgtInc    is 88,
          tgtLan    is 120,
          trnsfrAlt is 500000,
          tgtAp1    is 15000,
          tgtPe1    is 15000.
          
//

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_node").
runOncePath("0:/lib/lib_antenna").
runOncePath("0:/lib/lib_solar").

//Paths to other scripts used here
local incChangeScript to "local:/inc_change". 
compile("0:/a/simple_inclination_change") to incChangeScript.

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to rm(0).

disp_main().

local mnvNode is 0.
local mnvObj is lex().

local tStamp to 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and throttle > 0 then 
{
    safe_stage().
    preserve.
}

// Payload onDeploy trigger
if ship:partsTaggedPattern("onDeploy"):length > 0 
{
    when stage:number <= 0 then 
    {
        for p in ship:partsTaggedPattern("onDeploy") 
        {
            if p:tag:matchesPattern("solar") 
            {
                activate_solar(p).
            } 
            else if p:tag:matchesPattern("comm.omni") 
            {
                activate_antenna(p).
            }
        }
    }
}

main().
end_main().

//Main
local function main 
{
    until runmode = 99 
    {

        //Get the list of science experiments
        if runmode = 0 
        {
            set runmode to rm(2).
        }
        
        //Activate the antenna
        else if runmode = 2 
        {
            out_msg("Deploying antenna").

            for p in ship:partsTaggedPattern("comm.dish") 
            {
                if not p:tag:matchesPattern("onDeploy") and not p:tag:matchesPattern("onTouchdown") 
                {
                    activate_antenna(p).
                }
            }

            for p in ship:partsTaggedPattern("comm.omni") 
            {
                if not p:tag:matchesPattern("onDeploy") and not p:tag:matchesPattern("onTouchdown") 
                {
                    activate_antenna(p).
                }
            }
            
            set runmode to rm(3).
        }

        //Sets the transfer target
        else if runmode = 3 
        {
            out_msg("Setting target to " + tgtBody).
            set target to tgtBody.
            set runmode to rm(7).
        }

        else if runmode = 7 
        {
            out_msg("Checking inclination").
            if ship:orbit:inclination < target:orbit:inclination - 2.5 or ship:orbit:inclination > target:orbit:inclination + 2.5 
            {
                out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + target:obt:inclination + "]").
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }
            set runmode to rm(15).
        }

        // Gets the transfer parameters for the burn
        // Adds the node
        else if runmode = 15 
        {
            out_msg("Getting transfer object and adding node").
            if not hasTarget set target to tgtBody.
            set mnvObj to get_transfer_obj().
            set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
            add mnvNode. 

        // Optimizes the maneuver node via hill climbing
            out_msg("Optimimzing transfer node").
            local accuracy is 0.005.
            set mnvNode to optimize_transfer_node(mnvNode, trnsfrAlt, tgtInc, target, accuracy).
            set sVal to lookDirUp(mnvNode:burnVector, sun:position).
            set tStamp to time:seconds + 5.
            until time:seconds >= tStamp 
            {
                update_display().
                disp_timer(tStamp, "mnvObj creation").
            }
            disp_clear_block("timer").
            set runmode to rm(20).
        }

        if runmode = 20 
        {
            if not hasNode 
            {
                set runmode to rm(15).
            } else 
            {
                set mnvObj to get_burn_obj_from_node(nextNode).
                set runmode to rm(30).
            }
        }

        //Warps to the burn node
        else if runmode = 30 
        {
            out_msg("Warping to burn node").
            warp_to_burn_node(mnvObj).
            set runmode to rm(35).
        }

        //Executes the transfer burn
        else if runmode = 35 
        {
            out_msg("Executing burn node").
            exec_node(nextNode).
            set runmode to rm(37).
        }

        else if runmode = 37 
        {
            out_msg("Setting onDeploy triggers").
            when stage:number <= 1 then 
            {
                for p in ship:partsTaggedPattern("solar.array.*.onDeploy") 
                {
                    activate_solar(p).
                }

                for p in ship:partsTaggedPattern("comm.dish.*.onDeploy") 
                {
                    activate_antenna(p).
                }

                for p in ship:partsTaggedPattern("comm.omni.*.onDeploy") 
                {
                    activate_antenna(p).
                }
            }

            set runmode to rm(40).
        }

        //Then warps to the SOI change
        else if runmode = 40 
        {
            
            out_msg("SOI Warp").

            set tStamp to time:seconds + 5.
            until time:seconds >= tStamp 
            {
                update_display().
                disp_timer(tStamp, "soi warp").
            }

            disp_clear_block("timer").

            if ship:body:name <> tgtBody 
            {
                warp_to_next_soi().
            }
            
            until ship:body:name = tgtBody 
            {
                update_display().
            }
                
            set runmode to rm(45).
        }

// Circularization node
        // Adds a 60s timer for player to do anything needed before warp
        else if runmode = 45 
        {

            out_msg("Circ burn countdown").
            
            set tStamp to time:seconds + 5.
            until time:seconds >= tStamp 
            {
                update_display().
                disp_timer(tStamp, "circ node").
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to rm(47).
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 47 
        {
            out_msg("Adding capture node").
            set mnvNode to add_capture_node(tgtAp1).
            set runmode to rm(55).
        }

        //Gets burn data from the node
        else if runmode = 55 
        {
            out_msg("Getting burn object from existing node").
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to rm(60).
        }

        //Warps to the burn node
        else if runmode = 60 
        {
            out_msg("Warping to burn node").
            set sVal to lookDirUp(mnvNode:burnVector, sun:position).
            wait until shipSettled().
            warp_to_burn_node(mnvObj).
            set runmode to rm(65).
        }

        //Executes the circ burn
        else if runmode = 65 
        {
            out_msg("Executing burn node").
            exec_node(nextNode).
            wait 2.
            set runmode to rm(70).
        }

        else if runmode = 70 
        {
            out_msg("Checking orbit inclination").
            if (ship:orbit:inclination < tgtInc - 2 or ship:orbit:inclination > tgtInc + 2) 
            {
                out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + tgtInc + "]").
                runpath(incChangeScript, tgtInc, tgtLan).
                deletePath(incChangeScript).
            }

            set runmode to rm(75).
        }

        //Adds a hohmann burn top lower to final altitude
        else if runmode = 75 
        {
            out_msg("Lowering to final altitude").
            exec_circ_burn("ap", tgtPe1).
            set runmode to rm(80).
        }

        //
        else if runmode = 80 
        {
            out_msg("Final alt circ burn").
            exec_circ_burn("pe", tgtAp1).
            set runmode to rm(98).
        }

        //Preps the vessel for long-term orbit
        else if runmode = 98 
        {
            end_main().
            set runmode to rm(99).
        }

        set runmode to stateObj["runmode"].
        update_display().
    }
}


//Functions
local function end_main {
    unlock steering.
    unlock throttle.

    disp_clear_block_all().

    logStr("Mission completed").
}