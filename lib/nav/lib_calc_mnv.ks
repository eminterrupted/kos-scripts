@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_twr").


//-- Functions --//


//Returns the burn duration of a single stage, used in other calculations
//
global function get_burn_dur_by_stage {
    parameter _deltaV,
              _stageNum is stage:number.
    
    // Returns the engines in the stage if the provided stage has any.
    // If no engines found, returns the next stage engines
    local engineList to choose get_engs_for_stage(_stageNum) if get_engs_for_stage(_stageNum):length > 0 else get_engs_for_next_stage().
    
    // Engine performance object for the given list of engines.
    // This includes thrust, isp, and exhaust velocity for each engine
    local enginePerf to get_eng_perf_obj(engineList).

    // Effective exhaust velocity of the stage, based on the effective isp
    local exhaustVel to get_engs_exh_vel(engineList, ship:apoapsis).

    // Mass of the vessel at this stage (including all later stage mass)
    local vesselMass to get_ves_mass_at_stage(_stageNum).

    // Add up the thrust for each engine in the stage, using the 
    // possible thrust method (which returns thrust even when engine is off)
    local stageThrust to 0.
    for e in enginePerf:keys {
        set stageThrust to stageThrust + enginePerf[e]["thr"]["poss"].
    }

    // Returns the duration that this stage will take to burn it's fuel
    // This is basically the rocket equation
    return ((vesselMass * exhaustVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (_deltaV / exhaustVel)))).
}


// Returns the total duration to burn the provided deltav, taking staging into account
global function get_burn_dur {
    parameter _deltaV.  // Total delta v of the burn
    
    // Variables
    local allDur   is 0.    // Var for total duration of the burn
    local stageDur is 0.    // Var for total duration of the stage's burn

    // Gets the stages needed to execute the required deltaV,
    // along with the deltaV available in each stage
    local dvObj is get_stages_for_dv(_deltaV).

    // Iterate through the stages, calculating how long it takes
    // to burn the necessary amount for each stage. 
    for key in dvObj:keys {
        set stageDur to get_burn_dur_by_stage(dvObj[key], key).
        set allDur to allDur + stageDur.
    }

    // Total duration of the burn
    return allDur.
}


// Returns detailed burn data from a node in a lexicon, includes
// the original node in the object for easy reference later
global function get_burn_obj_from_node {
    parameter _mnvNode.

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local dV        to _mnvNode:burnvector:mag.     // DeltaV from the burn vector
    local nodeAt    to time:seconds + _mnvNode:eta. // Time in UT of the node
    local burnDur   to get_burn_dur(dv).            // Total duration of the burn
    local halfDur   to get_burn_dur(dv / 2).        // Duration of half of the burn
    local burnEta   to nodeAt - halfDur.            // When to start the burn
    local burnEnd   to nodeAt + halfDur.            // When the burn should end

    return lexicon("dV", dv,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt, "mnv", _mnvNode).
}


// Returns a simple coplanar burn object
// Assumes burn is either at Ap or Pe
global function get_coplanar_burn_data {
    parameter _newAlt,
              _burnLocation is "ap".

    // Sets the starting point of the burn. Since this is 
    // a simple burn, it should occur at either Ap or Pe. 
    local nodeAt to choose time:seconds + eta:apoapsis if _burnLocation = "ap" else time:seconds + eta:periapsis.

    // Determines the starting altitude based on the burn location
    local startAlt to choose ship:periapsis if _burnLocation = "ap" else ship:apoapsis.

    // Burn calculations
    local dV to get_dv_for_mnv(_newAlt, startAlt, ship:body).   // DeltaV needed
    local burnDur to get_burn_dur(dV).                          // Total duration of the burn
    local halfDur to get_burn_dur(dv / 2).                      // Duration of half of the burn
    local burnEta to nodeAt - halfDur.                          // When to start the burn
    local burnEnd to nodeAt + halfDur.                          // When the burn should end

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt).
}


// Returns a node-formatted list used to create a maneuver node.
// Inputs are when to burn, and the change we want to make in altitude.
// Calculates the needed deltaV
global function get_mnv_param_list {    
    parameter _nodeAt                   // Timestamp of mnv
              ,_startAlt                // Starting altitude of mnv
              ,_finalAlt                // Target altitude after mnv
              ,_mnvBody is ship:body.   // Body SOI where mnv occurs

    // Returns the deltaV needed to execute the change in altitude
    // around the provided body
    local dv to get_dv_for_mnv(_finalAlt, _startAlt, _mnvBody).
    
    // Node formatted list struct
    return list(_nodeAt, 0, 0, dv).
}


// Returns a coplanar mun transfer burn object. Must be called 
// with a node timestamp derived from get_mun_transfer_window 
// and have the desired mun set as target
global function get_mun_xfr_burn_data {
    parameter _nodeAt.

    // If no target is set, return false. This will fail
    if not hasTarget return false.

    // Burn details
    local dv to get_dv_for_mun_transfer(target).    // deltaV for transfer
    local burnDur to get_burn_dur(dV).              // Duration of the burn
    local halfDur to get_burn_dur(dV / 2).          // Duration to burn half the dV
    local burnEta to (_nodeAt) - (halfDur).         // UT timestamp to start the burn

    return lex("dv", dv, "nodeAt", _nodeAt, "burnDur", burnDur, "burnETA", burnETA).
}



// Returns an object describing the transfer window to a mun
// TODO - Call from above to abstract from mainline scripts
global function get_transfer_phase_angle {
    parameter _startAlt is (ship:apoapsis + ship:periapsis) / 2, // Average altitude
              _startBody is ship:body.                           // Body we are starting from


    // If no target set, return false. This will fail
    if not hasTarget return false.

    //Semi-major axis calcs
    local curSMA is _startAlt + _startBody:radius.      // SMA we are starting from
    local tgtSMA is target:altitude + _startBody:radius.// SMA we want at the target
    local hohSMA to (curSMA + tgtSMA) / 2.              // The halfway point for hohmann transfer

    // Transfer phase angle
    local transferPhaseAng to 180 - (1 / (2 * sqrt(tgtSMA ^ 3 / hohSMA ^ 3)) * 360).
    
    // UT Timestamp of point we will reach the transfer phase angle
    local nodeAt to get_transfer_window(transferPhaseAng) - 60.

    return lex("xfrPhaseAng", transferPhaseAng, "nodeAt", nodeAt).
}


// Returns a timestamp of next transfer window based on the 
// phase angle found in get_mun_transfer_phase
global function get_transfer_window {
    parameter _transferPhaseAng,    // The phase angle of the transfer window
              _tgt is target.       // The target (body or ship)


    // Get the period of the phase angle (change per second) 
    // Takes a sample of the change in phase angle to the target 
    // over the course of 5 seconds to get phase change / sec
    print "MSG: Sampling phase angle period" at (2, 7).
    local p0 to get_phase_angle(_tgt).
    wait 5. 
    local p1 to get_phase_angle(_tgt).
    local phasePeriod to abs((p1 - p0) / 5).

    // Update the phase angle for calculation below
    local phaseAng to get_phase_angle(_tgt).

    // Calculates the transfer window based on whether it's in front of us or behind us
    local xfrWindow to choose (time:seconds + ((phaseAng - _transferPhaseAng) / phasePeriod)) if phaseAng > _transferPhaseAng else (time:seconds + (((phaseAng + 360) - _transferPhaseAng) / phasePeriod)).
    
    print "                                " at (2, 7).
    return xfrWindow.
}


// Gets a transfer object for the current target
// Combines both transfer window and transfer burn data functions
// Returns a flat object with all burn data
global function get_transfer_obj {

    // If the target is not set, return false
    if target = "" return false.
       
    // Transfer window
    local transferWindow to get_transfer_phase_angle().

    // Burn data based on the window
    local burnData to get_mun_xfr_burn_data(transferWindow["nodeAt"]).
    local transferObj to lex("tgt", target).

    for key in transferWindow:keys {
        set transferObj[key] to transferWindow[key].
    }

    for key in burnData:keys {
        set transferObj[key] to burnData[key].
    }

    return transferObj.
}