//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/nav/lib_deltav.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").


global function get_burn_data {
    parameter newAlt.

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local nodeAt to time:seconds + eta:apoapsis.

    //get deltaV for the burn
    local dV to get_req_dv_at_alt(newAlt).

    //local burnDur to exhVel * ln(startMass) - exhVel * ln(endMass).
    local burnDur to get_burn_dur(dV). 
    local burnEta to nodeAt - (burnDur / 2).
    local burnEnd to nodeAt + (burnDur / 2).

    logStr("get_burn_data").
    logStr("[dV: " + dV + "][burnDur: " + burnDur + "][nodeAt: " + nodeAt + "][burnEta: " + burnEta + "]").

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt).
}


//Checks the input heading and normalizes it for a 360 degree compass
global function check_hdg {

    parameter refHdg to 90.
    
    local retHdg to 90.

    //Validate heading provided to within bounds
    if refHdg <= 360 and refHdg >= 0 {   
        set retHdg to refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if refHdg > 360 { 
        from { local x to refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if refHdg < 0 {
        from { local x to refHdg.} until x > 0 step { set x to x + 360. } do {
            set retHdg to x.
            wait 0.001.
        }
    }

    return retHdg.
}.


//Get the current compass heading in degrees
global function get_nav_heading {
    return mod( 360 - latlng( 90, 0):bearing, 360).
}.


//Gets the current signed roll value [-180, 180]
global function get_nav_roll {
    parameter   vecA,
                vecB,
                normal.

    local ang to vAng(vecA, vecB).
    if vDot( vCrs(vecA, vecB), normal) < 0 {
        return -ang.
    }

    return ang.
}.


//Get the current pitch in degrees [-90, 90]
global function get_nav_pitch {
    return 90 - vAng(up:vector, facing:vector).
}.


global function get_burn_dur_by_stg {
    parameter pDv,
              pStg is stage:number.
    
    local eList to choose get_engs_for_stg(pStg) if get_engs_for_stg(pStg):length > 0 else get_engs_for_next_stg().
    local engPerfObj to get_eng_perf_obj(eList).
    local exhVel to get_engs_exh_vel(eList, ship:apoapsis).
    local vMass to get_vmass_at_stg(pStg).

    local stageThrust to 0.
    for e in engPerfObj:keys {
        set stageThrust to stageThrust + engPerfObj[e]["thr"]["poss"].
    }

    // print "stageThrust: " + stageThrust at (2, 54).
    // print "exhVel:      " + exhVel at (2, 55).
    // print "vMass:       " + vMass at (2, 56).
    // print "elist:       " + eList at (2, 57).
    // print "engPerfObj:  " + engPerfObj at (2, 62).


    return ((vMass * exhVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (pDv / exhVel)))).
}


global function get_burn_dur {
    parameter pDv.
    
    logStr("get_burn_dur").
    local alldur is 0.
    local stgdur is 0.
    local dvObj to get_stages_for_dv(pDv).

    for k in dvObj:keys {
        set stgdur to get_burn_dur_by_stg(dvObj[k], k).
        set alldur to alldur + stgdur.
    }

    return alldur.
}