//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/nav/lib_deltav.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").


global function get_burn_data {
    parameter newAlt.

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local startMass to get_mass_at_stage(stage:number).
    local nodeAt to time:seconds + eta:apoapsis.
    local eList to list().
    list engines in eList.

    //get deltaV for the burn
    local dV to get_deltav_at_ap(newAlt).

    //Get engines and stages for checking to see if we need to stage mid burn
    //Calc fuel burn
    local fuelBurned to startMass - ( startMass / (constant:e ^ (dV / get_engs_exh_vel(elist, newAlt)))).
    local endMass to startMass - fuelBurned.

    //local burnDur to exhVel * ln(startMass) - exhVel * ln(endMass).
    local burnDur to get_burn_dur(startMass, dV). 
    local burnEta to nodeAt - (burnDur / 2).
    local burnEnd to nodeAt + (burnDur / 2).

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt,"startMass",startMass,"endMass",endMass).
}


global function get_engs_exh_vel {
    parameter engList to get_active_engines(),
              pAlt to ship:apoapsis.

    //local apIsp to choose eng:visp if pAlt >= body:atm:height else eng:ispAt(body:atm:altitudepressure(pAlt)).
    
    local apIsp to get_avail_isp(body:atm:altitudePressure(pAlt), engList).
    return constant:g0 * apIsp.
}


global function get_eng_exh_vel {
    parameter eng,
              pAlt to body:atm:height.

    local apIsp to choose eng:visp if pAlt >= body:atm:height else eng:ispAt(body:atm:altitudepressure(pAlt)).
    return constant:g0 * apIsp.
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


global function get_burn_dur {
    parameter pMass,
              pDv.
    
    local eList to get_active_engines().
    local engPerfObj to get_eng_perf_obj(eList).
    local exhVel to get_engs_exh_vel(eList, ship:apoapsis).

    local stageThrust to 0.
    for e in engPerfObj:keys {
        set stageThrust to stageThrust + engPerfObj[e]["thr"]["poss"].
    }

    return ((pMass * exhVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (pDv / exhVel)))).
}