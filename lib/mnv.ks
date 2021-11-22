@lazyGlobal off.

// Dependencies
// #include "0:/lib/globals"
// #include "0:/lib/burnCalc"
// #include "0:/lib/disp"
// #include "0:/lib/nav".
// #include "0:/lib/util"

// *~ Variables ~* //


// *~ Functions ~* //
// #region

// ExecNodeBurn :: <node> -> <none>
// Given a node object, executes it
global function ExecNodeBurn
{
    parameter mnvNode is node(),
              showVec is false.

    local magVec to v(0, 0, 0).

    local dv to mnvNode:deltaV:mag.
    local burnDur to CalcBurnDur(dv).
    local fullDur to burnDur[0].
    local halfDur to burnDur[1].

    local burnEta to mnvNode:time - halfDur. 
    set MECO    to burnEta + fullDur.
    lock dvRemaining to abs(mnvNode:burnVector:mag).

    lock rVal to r(0, 0, ship:facing:roll).
    local sVal to mnvNode:burnvector:direction - rVal.
    local tVal to 0.
    lock steering to sVal.
    lock throttle to tVal.

    ArmAutoStaging().
    
    if showVec
    {
        set magVec to vecDraw(ship:position, mnvNode:burnvector, purple, "BurnVector", 2.5, true, 0.25, true).
        set magVec:vectorUpdater to { return mnvNode:burnvector.}.
    }

    InitWarp(burnEta, "Burn ETA").

    until time:seconds >= burnEta
    {
        set sVal to mnvNode:burnvector:direction - rVal.
        DispBurn(burnEta, dvRemaining, MECO - time:seconds).
    }

    local dv0 to mnvNode:deltav.
    lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.

    OutMsg("Executing burn").
    OutInfo().
    OutInfo2().
    set tVal to 1.
    set sVal to lookDirUp(mnvNode:burnVector, sun:position).
    until false
    {
        if vdot(dv0, mnvNode:deltaV) <= 0.01
        {
            set tVal to 0.
            break.
        }
        else
        {
            set tVal to max(0.02, min(mnvNode:deltaV:mag / maxAcc, 1)).
        }
        DispBurn(time:seconds - burnEta, dvRemaining, MECO).
        wait 0.01.
    }

    OutTee("Maneuver Complete!").
    wait 1.
    clrDisp().
    if showVec
    {
        set magVec:vectorUpdater to DONOTHING.
        set magVec:show to false.
    }
    unlock steering.
    remove mnvNode.
}

// MatchIncBurn :: <ship>, <orbit>, <orbit>, [<bool>] -> <list>
// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt)     - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
// - [2] (nodeStruc)  - A maneuver node structure for this burn
global function IncMatchBurn
{
    parameter burnVes,      // Vessel that will perform the burn
              burnVesObt,   // The orbit where the burn will take place. This may not be the current orbit
              tgtObt,       // target orbit to match
              nearestNode is false. // If true, choose the nearest of AN / DN, not the cheapest

    // Variables
    local burn_utc to 0.

    // Normals
    local ves_nrm to ObtNormal(burnVesObt).
    local tgt_nrm to ObtNormal(tgtObt).

    // Total inclination change
    local d_inc to vang(ves_nrm, tgt_nrm).

    // True anomaly of ascending node
    local node_ta to AscNodeTA(burnVesObt, tgtObt).

    // ** IMPORTANT ** - Below is the "right" code, I am testing picking the soonest vs most efficient
    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 
    {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta. If nearestNode flag is set, choose the node with 
    // soonest ETA. Else, choose the cheapest node.
    if nearestNode 
    {
        set burn_utc to time:seconds + ETAtoTA(burnVesObt, node_ta).
        if burn_utc > ship:orbit:period / 2 
        {
            set node_ta to mod(node_ta + 180, 360).
            set burn_utc to time:seconds + ETAtoTA(burnVes:obt, node_ta).
        }
    }
    else 
    {
        set burn_utc to time:seconds + ETAtoTA(burnVesObt, node_ta).
    }

    // Get the burn unit direction (burnvector direction)
    local burn_unit to (ves_nrm + tgt_nrm):normalized.

    // Get deltav / burnvector magnitude
    local vel_at_eta to velocityAt(burnVes, burn_utc):orbit.
    local burn_mag to -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
    
    // Get the dV components for creating the node structure
    local burn_nrm to burn_mag * cos(d_inc / 2).
    local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).

    // Create the node struct
    local mnv_node to node(burn_utc, 0, burn_nrm, burn_pro).
    
    return list(burn_utc, burn_mag * burn_unit, mnv_node, burn_mag, burn_unit).
}

// #endregion