@lazyGlobal off.
clearScreen.

parameter stBody is ship:body,
          tgtBody is "Minmus",
          tgtAlt  is 25000.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_conics").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Set the target
if not hasTarget set target to nav_orbitable(tgtBody).

disp_main(scriptPath()).

// Variables
local burnAt        to 0.
local burnEta       to 0.
local dvCirc        to 0.
local dvExit        to 0.
local dvTrans       to 0.
local mnvExit       to node(0, 0, 0, 0).
local mnvCirc       to node(0, 0, 0, 0).
local mnvInc        to node(0, 0, 0, 0).
local mnvTrans      to node(0 ,0, 0, 0).
local mnvCircTime   to 0.
local mnvExitTime   to 0.
local mnvIncTime    to 0.
local mnvTransTime  to 0.
local mnvObt        to ship:orbit.
local tgtBodyAlt    to target:altitude - target:body:radius.


// Calculate ideal phase angle between stBody and tgtBody around kerbol
lock currentPhase to mod(360 + ksnav_phase_angle(target, stBody), 360).
local transferPhase to nav_transfer_phase_angle(target, stBody:orbit:semimajoraxis).
// Turn phase angle into transfer window

disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").

    // Calulate the timestamp to burn from the start body
    local angVelSt      to nav_ang_velocity(stBody, stBody:body).
    local angVelTgt     to nav_ang_velocity(target, target:body).
    local angVelPhase   to angVelSt - angVelTgt.
    set burnEta         to (currentPhase - transferPhase) / angVelPhase.
    if burnEta < 0 
    {
        set burnEta to burnEta + ship:orbit:period.
    }
    set mnvExitTime     to burnEta + time:seconds.

    print "Target           : " + target + "   " at (2, 23).
    
    print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
    print "Time to transfer : " + round(burnEta) at (2, 25).
    
    disp_msg().
    disp_info().

    // Get the amount of DV required for exit velocity
    set dvExit to mnv_dv_interplanetary_departure(stBody, target, ship:orbit:semiMajorAxis, tgtAlt + target:radius).
    print "Transfer dV      : " + round(dvExit[0], 2) + "m/s     " at (2, 27).
    print "Arrival  dV      : " + round(dvExit[1], 2) + "m/s     " at (2, 28).

    // Add the exit maneuver node
    set mnvExit to node(mnvExitTime, 0, 0, dvExit[0]).
    add mnvExit.
    wait 0.25.

    breakpoint().

    if mnvExit:orbit:nextPatch:apoapsis > mnvExit:orbit:nextPatch:body:soiRadius 
    {
        local curApo to mnvExit:orbit:nextPatch:apoapsis.
        until curApo < target:altitude / 2
        {
            remove mnvExit. 
            set mnvExit to node(mnvExit:time + 10, mnvExit:radialout, mnvExit:normal, mnvExit:prograde).
            add mnvExit.
            set curApo to mnvExit:orbit:nextPatch:apoapsis.
        }
    }

    // Add the circ node
    set mnvObt to nav_next_patch_for_node(mnvExit).
    set mnvCircTime to time:seconds + mnvObt:eta:apoapsis.
    
    // Get the dv and create a node for the circularization burn
    set dvCirc to mnv_dv_bi_elliptic(mnvObt:periapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:body).
    set mnvCirc to node(mnvCircTime, 0, 0, dvCirc[1]).
    add mnvCirc.
    wait 0.25.

    breakpoint().

    // Inclination matching
    set mnvObt to nav_next_patch_for_node(mnvCirc).
    set mnvInc    to mnv_inc_match_burn(ship, mnvObt, target:orbit)[2].
    set mnvIncTime to mnvInc:time. 
    add mnvInc.
    wait 0.25.

    breakpoint().

    copyPath("0:/main/maneuver/transfer_to_body", "data_0:/transfer_to_body").

    // We are now ready to execute these nodes prior to setting up the final transfer node to target
    mnv_exec_node_burn(nextNode).
    mnv_exec_node_burn(nextNode).
    mnv_exec_node_burn(nextNode).

    // Now perform the final transfer
    lock currentPhase to mod(360 + ksnav_phase_angle(), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to nav_transfer_phase_angle(target, ship:orbit:semimajoraxis - ship:body:radius).

    disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").

    // Calulate the transfer timestamp
    set angVelSt      to nav_ang_velocity(ship, target:body).
    set angVelTgt     to nav_ang_velocity(target, target:body).
    set angVelPhase   to angVelSt - angVelTgt.
    set burnEta       to (currentPhase - transferPhase) / angVelPhase.
    if burnEta < 0
    {
        set burnEta to burnEta + ship:orbit:period.
    }
    set mnvTransTime  to burnEta + time:seconds.

    print "Target           : " + target + "   " at (2, 23).
    
    print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
    print "Time to transfer : " + round(burnEta) at (2, 25).
    
    disp_msg().
    disp_info().

    // Get the amount of dv needed to get to the target
    set dvTrans to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtBodyAlt, tgtBodyAlt, tgtBodyAlt).
    print "Transfer dV      : " + round(dvTrans[0], 2) + "m/s     " at (2, 27).
    print "Arrival  dV      : " + round(dvTrans[1], 2) + "m/s     " at (2, 28).

    // Add the maneuver node
    set mnvTrans to mnv_opt_transfer_node(node(mnvTransTime, 0, 0, dvTrans[0]), target, tgtAlt, 0.01).
    add mnvTrans.

    mnv_exec_node_burn(nextNode).
