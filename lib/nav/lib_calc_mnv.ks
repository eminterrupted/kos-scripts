@lazyGlobal off.

runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_engine").

//-- Functions --//


// Returns the burn duration of a single stage, used in other calculations
//
global function get_burn_dur_by_stage {
    parameter _deltaV,
              _stageNum is stage:number.
    
    if verbose logStr("[get_burn_dur_by_stage] _deltaV: " + _deltaV + "   _stageNum: " + _stageNum).

    // Returns the engines in the stage if the provided stage has any.
    // If no engines found, returns the next stage engines
    local engineList    to engs_for_stg(_stageNum).
    if engineList:length = 0 {
        if verbose logStr("[get_burn_dur_by_stage]-> return: 0. No engines found in stage: " + _stageNum).
        return 0.
    }
    
    // Get performance data for the stage
    local stgThr        to poss_thr_for_eng_list(engineList).
    local exhaustVel    to get_engs_exh_vel(engineList, max(0, ship:apoapsis)).
    local vesselMass    to get_ves_mass_at_stage(_stageNum).

    // Returns the duration that this stage will take to burn its fuel
    // This is basically the rocket equation
    local burnDur       to ((vesselMass * exhaustVel) / stgThr) * ( 1 - (constant:e ^ (-1 * (_deltaV / exhaustVel)))).

    if verbose logStr("[get_burn_dur_by_stage]-> return: " + burnDur).
    return burnDur.
}


// Returns the total duration to burn the provided deltav, taking staging into account
global function get_burn_dur {
    parameter _deltaV.  // Total delta v of the burn
    
    if verbose logStr("[get_burn_dur] dV: " + _deltaV).

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

    if verbose logStr("[get_burn_dur]-> return " + allDur).

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

    local retObj to lexicon( 
        "dV", dv,
        "burnDur",burnDur,
        "halfDur",halfDur,
        "burnEta",burnEta,
        "burnEnd",burnEnd,
        "nodeAt",nodeAt,
        "mnv", _mnvNode
        ).

    return retObj.
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
    local dV to get_dv_for_prograde(_newAlt, startAlt, ship:body).   // DeltaV needed
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
    local dv to get_dv_for_prograde(_finalAlt, _startAlt, _mnvBody).
    
    // Node formatted list struct
    return list(_nodeAt, 0, 0, dv).
}


// Returns a coplanar transfer burn object. Must be called 
// with a node timestamp derived from get_mun_transfer_window 
// and have the desired target set
global function get_transfer_burn_data {
    parameter _nodeAt.

    // If no target is set, return false. This will fail
    if not hasTarget return false.

    // Burn details
    local dv to get_dv_for_tgt_transfer().    // deltaV for transfer
    local burnDur to get_burn_dur(dV).              // Duration of the burn
    local halfDur to get_burn_dur(dV / 2).          // Duration to burn half the dV
    local burnEta to (_nodeAt) - (halfDur).         // UT timestamp to start the burn

    return lex("dv", dv, "nodeAt", _nodeAt, "burnDur", burnDur, "burnETA", burnETA).
}



// Returns an object describing a transfer window to the current target
// TODO - Make _startBody a function call to get the common ancestor
global function get_transfer_phase_angle {
    parameter _startAlt is (ship:apoapsis + ship:periapsis) / 2, // Average altitude
              _startBody is body("Kerbin").                           // Body we are starting from


    // If no target set, return false. This will fail
    if not hasTarget return false.

    //Semi-major axis calcs
    local curSMA is _startAlt + _startBody:radius.      // SMA we are starting from
    local tgtSMA is target:altitude + _startBody:radius.// SMA we want at the target
    local hohSMA to (curSMA + tgtSMA) / 2.              // The halfway point for hohmann transfer

    // Transfer phase angle
    //local transferPhaseAng to choose 180 - (1 / (2 * sqrt(tgtSMA ^ 3 / hohSMA ^ 3)) * 360) if curSMA <= tgtSMA else -((1 / (2 * sqrt(tgtSMA ^ 3 / hohSMA ^ 3)) * 360)).
    local transferPhaseAng to 180 - (1/2 * (2 * constant():pi * sqrt(hohSMA ^ 3 / _startBody:mu)) * ((360 / (2 * constant():pi)) * sqrt( _startBody:mu / tgtSma ^ 3))).
    
// UT Timestamp of point we will reach the transfer phase angle
    local nodeAt to get_transfer_eta_next(transferPhaseAng).

    return lex("xfrPhaseAng", transferPhaseAng, "nodeAt", nodeAt).
}


// Returns a timestamp of next transfer window based on the 
// phase angle found in get_mun_transfer_phase
global function get_transfer_eta {
    parameter _transferPhaseAng,    // The phase angle of the transfer window
              _tgt is target.       // The target (body or ship)


    // Get the period of the phase angle (change per second) 
    // Takes a sample of the change in phase angle to the target 
    // over the course of 5 seconds to get phase change / sec
    out_msg("Sampling phase angle period").
    local p0 to get_phase_angle(_tgt).
    local tStamp to time:seconds + 5.
    until time:seconds >= tStamp {
        update_display().
        disp_timer(tStamp, "Phase Sampling").
    }
    local p1 to get_phase_angle(_tgt).
    local phasePeriod to abs(abs(p1) - abs(p0)) / 5.

    print "Phase Period: " + phasePeriod at (2,23).

    disp_clear_block("timer").

    // Update the phase angle for calculation below
    local phaseAng to get_phase_angle(_tgt).

    // Calculates the transfer window based on whether it's in front of us or behind us
    local xfrWindow to choose (time:seconds + ((phaseAng - _transferPhaseAng) / phasePeriod)) if phaseAng > _transferPhaseAng else (time:seconds + (((phaseAng + 360) - _transferPhaseAng) / phasePeriod)).
    
    out_msg().
    return xfrWindow.
}


// Returns a timestamp of next transfer window based on the 
// phase angle found in get_transfer_phase_angle
global function get_transfer_eta_next {
    parameter _transferAng.    // The phase angle of the transfer window


    // Get the period of the phase angle (change per second) 
    // Takes a sample of the change in phase angle to the target 
    // over the course of 5 seconds to get phase change / sec
    out_msg("Sampling phase angle period").
    local p0 to get_phase_angle(target).
    local tStamp to time:seconds + 3.
    until time:seconds >= tStamp {
        update_display().
        disp_timer(tStamp, "Phase Sampling").
    }
    local p1 to get_phase_angle(target).
    local phasePeriod to abs(abs(p1) - abs(p0)) / 3.

    disp_clear_block("timer").

    // Update the phase angle for calculation below
    local phaseAng to get_phase_angle(target).
    
    // Handle negative phase angle numbers
    set phaseAng to mod(phaseAng + 360, 360).
    set _transferAng to mod(_transferAng + 360, 360).

    // Get the total number of degrees to travel
    local degToWait to abs(abs(phaseAng) - abs(_transferAng)).

    // Calculates the transfer window based on amount of time it takes
    // to travel the needed degrees.
    local xfrWindow to (time:seconds + (degToWait / phasePeriod)).

    out_msg().
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
    local burnData to get_transfer_burn_data(transferWindow["nodeAt"]).
    local transferObj to lex("tgt", target).

    for key in transferWindow:keys {
        set transferObj[key] to transferWindow[key].
    }

    for key in burnData:keys {
        set transferObj[key] to burnData[key].
    }

    return transferObj.
}


global function cache_mnv_obj {
    parameter mnvObj.

    local objPath is "local:/mnvCache.json".

    writeJson(mnvObj, objPath).

    return objPath.
}