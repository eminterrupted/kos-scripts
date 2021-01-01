@lazyGlobal off.

runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_isp").

//--
global function get_twr_for_modes_stage_pres {
    
    parameter pMassMode,
              pThrustMode,
              pStage,
              pPres.

    local stageMass is get_mass_at_mode_stage(pMassMode, pStage).
    local srfGrav is (constant:g * body:mass) / (body:radius ^ 2 ).
    local stageThrust is get_thrust_for_mode_stage_pres(pThrustMode, pStage, pPres).
    
    if stageThrust <> 0 {
        //return ((stageMass * 1000) / (stageThrust * srfGrav)).
        return (stageThrust / (stageMass * 100) * srfGrav).
    }
    else return 0.
}


global function get_twr_for_modes_stage_alt {
    
    parameter _pMassMode,
              _pThrustMode,
              _pStage,
              _pAlt.
    
    return get_twr_for_modes_stage_pres(_pMassMode, _pThrustMode, _pStage, body:atm:altitudePressure(_pAlt)).
}


global function get_twr_for_modes_parts_pres {
    parameter pMassMode,
              pThrustMode,
              pList,
              pPres.

    local srfGrav is (constant:g * body:mass) / (body:radius ^ 2).
    local stageMass is get_mass_for_mode_parts(pMassMode, pList).
    local stageThrust is get_thrust_for_mode_parts_pres(pThrustMode, pList, pPres).

    if stageThrust <> 0 {
        return (stageThrust / (stageMass * 100) * srfGrav).
    }
    else return 0.
}


global function get_twr_for_modes_parts_alt {
    parameter _pMassMode,
              _pThrustMode,
              _pList,
              _pAlt.

    return get_twr_for_modes_parts_pres(_pMassMode, _pThrustMode, _pList, body:atm:altitudePressure(_pAlt)).
}