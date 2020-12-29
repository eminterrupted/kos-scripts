@lazyGlobal off.

parameter _tgt is "Megfrid's Debris".
//

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_rendezvous").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

//Paths to other scripts used here
local incChangeScript to "local:/incChange". 
copyPath("0:/_main/adhoc/simple_inclination_change", incChangeScript).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().

local mnvNode is 0.
local mnvObj is lex().

local tStamp to 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position).
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
            set runmode to 2.
        }
        
        //Activate the antenna
        else if runmode = 2 {
            for p in ship:partsTaggedPattern("comm.dish") {
                if not p:tag:matchesPattern("onDeploy") {
                    activate_dish(p).
                }
            }

            for p in ship:partsTaggedPattern("comm.omni") {
                if not p:tag:matchesPattern("onDeploy") {
                    activate_omni(p).
                }
            }
            
            set runmode to 3.
        }

        //Sets the transfer target
        else if runmode = 3 {
            set target to orbitable(_tgt).
            set runmode to 7.
        }

        else if runmode = 7 {
            if ship:orbit:inclination < target:orbit:inclination - 2.5 or ship:orbit:inclination > target:orbit:inclination + 2.5 {
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }
            set runmode to 15.
        }

        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            set mnvObj to get_transfer_obj().
            set runmode to 25.
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
            add mnvNode. 

            local accuracy is 0.001.
            set mnvNode to optimize_existing_node(mnvNode, target:orbit:periapsis, "pe", target, accuracy).
            
            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            warp_to_burn_node(mnvObj).
            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            exec_node(nextNode).
            set runmode to 37.
        }
    }
}