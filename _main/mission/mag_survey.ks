@lazyGlobal off.

parameter _rVal is 0.

// Change these variables per orbit
local tgtEcc is 0.225.
local tgtInc is 20.
local tgtLan is 135.
// End user-managed variables

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").

local incScript is "local:/inc_change".
if not exists(incScript) {
    local kscIncScript is "0:/a/inclination_change".
    compile(kscIncScript) to incScript.
    set incScript to "local:/inc_change".
}

local obtScript to "local:/orbit_change".
if not exists(obtScript) {
    local kscObtScript is "0:/a/simple_orbit_change".
    compile(kscObtScript) to obtScript.
}

local runmode to init_rm(0).
local sciList is get_sci_mod_for_parts(ship:parts).
local tgtAp is 0.
local tgtPe is info:altForSci[ship:body:name] - 5000.
local tStamp is 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.

//Staging trigger
when stage:liquidFuel < 0.1 and throttle > 0 then {
    safe_stage().
    preserve.
}

// Program
update_display().
main().

//Main function
local function main {
    until runmode = 99 {

        //Deploy the sat panels / antennas if not already
        if runmode = 0 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            logStr("Beginning mag_survey").
            logStr("RM[0]: Setting up orbital configuration").
            out_msg("Setting up panel / antenna config").

            panels on.

            local dishList is ship:partsTaggedPattern("comm.dish").
            if dishList:length > 0 {
                for d in dishList {
                    activate_antenna(d).
                    logStr("Comm object Dish activated").
                    wait 1.
                    set_dish_target(d, kerbin:name).
                    logStr("Dish target: " + get_dish_target(d)).
                }
            }

            set runmode to rm(5).
        }

        // Check our inclination. If low, run inclination change routine
        else if runmode = 5 {
            out_msg("Checking current inclination / LAN against target").
            if ship:orbit:inclination < tgtInc or not check_value(ship:obt:lan, tgtLan, 15) {
                runPath(incScript, tgtInc, tgtLan).
            } else {
                set runmode to rm(10).
            }
        }
            
        // Check to see if launch script placed us in proper eccentricity
        // If not, calc the needed Ap then run the orbit change script
        else if runmode = 10 {   
            out_msg("Checking current orbit ap / pe against target").
            if ship:orbit:eccentricity < tgtEcc or not ship:periapsis < info:altForSci[ship:body:name] {
                set tgtAp to get_ap_for_pe_ecc(tgtPe, tgtEcc).
                out_info("Values: tgtAp: " + round(tgtAp) + "  tgtPe: " + round(tgtPe) + " tgtEcc: " + tgtEcc).
                runPath(obtScript, tgtAp, tgtPe, ship:obt:argumentOfPeriapsis).
                set runmode to rm(20).
                
            } else {
                set runmode to rm(20).
            }
        }

        // Effective end of the loop. Will loop here forever until program is quit
        else if runmode = 20 {
            out_msg("Maneuvers complete, commencing survey").
            lock steering to lookDirUp(ship:prograde:vector, sun:position).
            set runmode to rm(30).
        }

                // Setup the science triggers
        else if runmode = 30 {
            
            logStr("Readying science experiments").
            out_msg("Deploying science").
            
            // Open bays if any, deploy the science experiments, wait for deployment
            if ship:partsTaggedPattern("bays"):length > 0 {
                out_info("Bay(s) detected, opening").
                bays on.
                set tStamp to time:seconds + 5.
                until time:seconds >= tStamp {
                    update_display().
                    disp_timer(tStamp, "bay deploy").
                }
            }

            out_msg("Preparing experiments").
            deploy_sci_list(sciList).
            set tStamp to time:seconds + 5.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "science deploy").
            }

            disp_clear_block("timer").

            when ship:altitude < info:altForSci[ship:body:name] then {
                log_sci_list(sciList).
                recover_sci_list(sciList, true).
                logStr("Science recovered in low orbit").
            }

            when ship:altitude > info:altForSci[ship:body:name] then {
                log_sci_list(sciList).
                recover_sci_list(sciList, true).
                logStr("Science recovered in high orbit").
            }

            set runmode to rm(50).
        }
        
        update_display().
    }
}