//lib for getting isp data

@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_engine").


// Functions
global function get_isp {
    
    if verbose logStr("[get_isp]").

    local avIsp  is 0.
    local relThr is 0. 
    local stgThr is 0.

    local eList is get_engs_for_stage(stage:number).
    
    for eng in eList {
        set stgThr to stgThr + eng:thrust.
        set relThr to relThr + (stgThr / eng:isp).
    }

    if stgThr = 0 or relThr = 0 {
        set avIsp to 0.
    } else {
        set avIsp to stgThr / relThr. 
    }

    if verbose logStr("[get_isp]-> return: " + avIsp).

    return avIsp.
}


global function get_avail_isp_for_parts {
    parameter _pres is body:atm:altitudePressure(ship:altitude),
              _pList is get_engs_for_stage(stage:number).

    if verbose logStr("[get_avail_isp_for_parts] _pres: " + _pres + "   _pList: " + _pList:join(";")).

    local avIsp  is 0.
    local relThr is 0.
    local stgThr is 0.
    
    for e in _pList {
        set stgThr to stgThr + e:possibleThrustAt(_pres).
        set relThr to relThr + (stgThr / e:ispAt(_pres)).
    }

    if stgThr = 0 or relThr = 0 {
        set avIsp to 0. 
    } else {
        set avIsp to stgThr / relThr. 
    }

    if verbose logStr("[get_avail_isp_for_parts]-> return: " + avIsp).

    return avIsp.
}


// Returns combined isp for a set of active engines at a given pressure.
// Default parameters are all active engines, and current altitude
global function get_avail_isp {
    parameter _eList is get_active_engs(),
              _pres is body:atm:altitudepressure(ship:altitude).
   
    if verbose logStr("[get_avail_isp] _pres: " + _pres + "   _eList: " + _eList:join(";")).

    local avIsp  is 0.
    local relThr is 0.
    local stgThr is 0.
    
    for e in _eList {
        set stgThr to stgThr + e:possibleThrustAt(_pres).
        set relThr to relThr + (stgThr / e:ispAt(_pres)).
    }

    if stgThr = 0 or relThr = 0 {
        set avIsp to 0. 
    } else {
        set avIsp to stgThr / relThr. 
    }


    if verbose logStr("[get_avail_isp]-> return: " + avIsp).

    return avIsp.
}


global function get_avail_isp_for_alt {
    parameter pAlt is ship:altitude, 
              pStage is stage:number. 

    local eList is get_engs_for_stage(pStage).

    return get_avail_isp_for_parts(body:atm:altitudePressure(pAlt), eList).
}