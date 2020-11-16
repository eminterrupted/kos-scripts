//lib for getting isp data

@lazyGlobal off.

//dependencies
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").


//////////////////////////
//Delegates


global function get_isp {
    
    local relThr is 0. 
    local stgThr is 0.

    local eList is get_engs_for_stg(stage:number).
    
    for eng in eList {
        set stgThr to stgThr + eng:thrust.
        set relThr to relThr + (stgThr / eng:isp).
    }

    if stgThr = 0 or relThr = 0 return 0.
    else return stgThr / relThr. 
}


global function get_avail_isp_for_parts {
    parameter pPres is body:atm:altitudePressure(ship:altitude),
              pList is get_engs_for_stg(stage:number).

    local relThr is 0.
    local stgThr is 0.
    
    for e in pList {
        set stgThr to stgThr + e:possibleThrustAt(pPres).
        set relThr to relThr + (stgThr / e:ispAt(pPres)).
    }

    if stgThr = 0 or relThr = 0 return 0. 
    else return stgThr / relThr. 
}


global function get_avail_isp {
    parameter pPres is body:atm:altitudepressure(ship:altitude),
              eList is get_active_engs().
   
    return get_avail_isp_for_parts(pPres, eList).
}


global function get_avail_isp_for_alt {
    parameter pAlt is ship:altitude, 
              pStage is stage:number. 

    local eList is get_engs_for_stg(pStage).

    return get_avail_isp_for_parts(body:atm:altitudePressure(pAlt), eList).
}


global function get_max_isp {
    parameter pPres is body:atm:altitudePressure(ship:altitude),
              pStage is stage:number.

    local eList is get_engs_for_stg(pStage).

    return get_max_isp_for_parts(pPres, eList).
}


global function get_max_isp_for_parts {
    parameter pPres is body:atm:altitudePressure(ship:altitude),
              pList is get_engs_for_stg(stage:number).

    local relThr is 0.
    local stgThr is 0.

    for eng in pList {
        set stgThr to stgThr + eng:maxThrustAt(pPres).
        set relThr to relThr + (stgThr / eng:ispAt(pPres)).
    }

    if stgThr = 0 or relThr = 0 return 0.
    else return stgThr / relThr.
}


global function get_max_isp_by_alt {
    parameter pAlt is ship:altitude, 
              pStage is stage:number. 

    local eList is get_engs_for_stg(pStage).
    
    return get_max_isp_for_parts(body:atm:altitudePressure(pAlt), eList).
}


global function get_poss_isp {
    parameter pPres is body:atm:altitudePressure(ship:altitude),
              pStage is stage:number.

    local eList is get_engs_for_stg(pStage).

    return get_poss_isp_for_parts(pPres, eList).
}


global function get_poss_isp_for_parts {
    parameter pPres is body:atm:altitudePressure(ship:altitude),
              plist is get_engs_for_stg(stage:mnumber).

    local relThr is 0.
    local stgThr is 0.

    for eng in pList {
        set stgThr to stgThr + eng:possibleThrustAt(pPres).
        set relThr to relThr + (stgThr / eng:ispAt(pPres)).
    }

    if stgThr = 0 or relThr = 0 return 0. 
    else return stgThr / relThr. 
}


global function get_poss_isp_by_alt {
    parameter pAlt is ship:altitude, 
              pStage is stage:number. 

    local eList is get_engs_for_stg(pStage).

    return get_poss_isp_for_parts(body:atm:altitudePressure(pAlt), eList).
}