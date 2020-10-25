//lib for getting engine performance data
@lazyGlobal off. 

runOncePath("0:/lib/lib_init.ks").


//Functions for delegates
    // local function p_thrust { parameter p. return p:thrust.}
    // local function p_avail_thrust { parameter p, pPres. return p:availableThrustAt(pPres).}
    // local function p_max_thrust { parameter p, pPres. return p:maxThrustAt(pPres).}
    // local function p_poss_thrust { parameter p, pPres. return p:possibleThrustAt(pPres).}


//Available thrust - Max throttle for active engines with limiter respected
global function get_avail_thrust {
    parameter pStage is stage:number,
                pPres is body:atm:altitudePressure(ship:altitude). 

    return get_thrust_for_mode_stage_pres("avail", pStage, pPres).
}

global function get_avail_thrust_for_alt {
    parameter pStage is stage:number,
                pAlt is ship:altitude. 

    return get_thrust_for_mode_stage_alt("avail", pStage, pAlt).
}
    

//Current thrust - Max throttle for active engines with limiter respected
global function get_thrust {
    parameter pStage is stage:number,
                pPres is body:atm:altitudePressure(ship:altitude). 

    return get_thrust_for_mode_stage_pres("cur", pStage, pPres).
}


//Max thrust - Max throttle for active engines with limiter bypassed
global function get_max_thrust {
    parameter pStage is stage:number, 
                pPres is body:atm:altitudePressure(ship:altitude).

    return get_thrust_for_mode_stage_pres("max", pStage, pPres).
}

global function get_max_thrust_for_alt {
    parameter pStage is stage:number, 
                pAlt is ship:altitude.

    return get_thrust_for_mode_stage_alt("max", pStage, pAlt).
}


//Possible thrust - Max throttle with all engines active (even if not now)
global function get_poss_thrust {
    parameter pStage is stage:number,
                pPres is body:atm:altitudePressure(ship:altitude).

    return get_thrust_for_mode_stage_pres("poss", pStage, pPres). 
}

global function get_poss_thrust_for_alt {
    parameter pStage is stage:number, 
                pAlt is ship:altitude.

    return get_thrust_for_mode_stage_alt("poss", pStage, pAlt).
}



//Main Thrust Functions
global function get_thrust_for_mode_parts_pres {
    parameter pThrustMode,
              pList,
              pPres.

    local partThrust is 0.
    
    for p in pList {
        if p:isType("engine") {
            if pThrustMode = "cur" set partThrust to partThrust + p:thrust.
            else if pThrustMode = "avail" set partThrust to partThrust + p:availableThrustAt(pPres).
            else if pThrustMode = "poss" set partThrust to partThrust + p:possibleThrustAt(pPres).
            else if pThrustMode = "max" set partThrust to partThrust + p:maxThrustAt(pPres).
        }
    }

    return partThrust. 
}


global function get_thrust_for_mode_parts_alt {
    parameter pThrustMode,
              pList,
              pAlt.

    return get_thrust_for_mode_parts_pres(pThrustMode, pList, body:atm:altitudePressure(pAlt)).
}


global function get_thrust_for_mode_stage_alt {
    parameter pThrustMode,
              pStage,
              pAlt.

    local pList is list().

    for p in ship:parts {
        if p:stage = pStage pList:add(p).
    }

    return get_thrust_for_mode_parts_pres(pThrustMode, pList, body:atm:altitudePressure(pAlt)).
}


global function get_thrust_for_mode_stage_pres {
    parameter pThrustMode,
              pStage,
              pPres.
              
    local pList is list().

    for p in ship:parts {
        if p:stage = pStage pList:add(p).
    }

    return get_thrust_for_mode_parts_pres(pThrustMode, pList, pPres).
}