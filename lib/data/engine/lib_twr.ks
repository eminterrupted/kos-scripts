@lazyGlobal off.

runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").

 //Delegates

     //twr
     //global get_twr is get_twr_for_modes_stage_alt@:bind("mass", "cur", stage:number, ship:altitude).
    
//     //available - only active engies
//     global get_avail_twr_for_alt is get_twr_for_modes_stage_alt@:bind("mass", "avail", stage:number).
//     global get_avail_twr_for_ap is get_twr_for_modes_stage_alt@:bind("mass", "avail", stage:number, ship:apoapsis).
//     global get_avail_twr_for_parts_alt is get_twr_for_modes_parts_alt@:bind("mass", "avail").
//     global get_avail_twr_for_parts_pres is get_twr_for_modes_parts_pres@:bind("mass", "avail").
//     global get_avail_twr_for_pe is get_twr_for_modes_stage_alt@:bind("mass", "avail", stage:number, ship:periapsis).
//     global get_avail_twr_for_pres is get_twr_for_modes_stage_pres@:bind("mass", "avail", stage:number).
//     global get_avail_twr_for_stage_alt is get_twr_for_modes_stage_alt@:bind("mass", "avail").
//     global get_avail_twr_for_stage_pres is get_twr_for_modes_stage_pres@:bind("mass", "avail").

//     //max - includes active engines with no limiters
//     global get_max_twr_for_alt is get_twr_for_modes_stage_alt@:bind("mass", "max", stage:number).
//     global get_max_twr_for_ap is get_twr_for_modes_stage_alt@:bind("mass", "max", stage:number, ship:apoapsis).
//     global get_max_twr_for_parts_alt is get_twr_for_modes_parts_alt@:bind("mass", "max").
//     global get_max_twr_for_parts_pres is get_twr_for_modes_parts_pres@:bind("mass", "max").
//     global get_max_twr_for_pe is get_twr_for_modes_stage_alt@:bind("mass", "max", stage:number, ship:periapsis).
//     global get_max_twr_for_pres is get_twr_for_modes_stage_pres@:bind("mass", "max", stage:number).
//     global get_max_twr_for_stage_alt is get_twr_for_modes_stage_alt@:bind("mass", "max").
//     global get_max_twr_for_stage_pres is get_twr_for_modes_stage_pres@:bind("mass", "max").

//     //possible - includes inactive engines
//     global get_poss_twr_for_alt is get_twr_for_modes_stage_alt@:bind("mass", "poss", stage:number).
//     global get_poss_twr_for_ap is get_twr_for_modes_stage_alt@:bind("mass", "poss", stage:number, ship:apoapsis).
//     global get_poss_twr_for_parts_alt is get_twr_for_modes_parts_alt@:bind("mass", "poss").
//     global get_poss_twr_for_parts_pres is get_twr_for_modes_parts_pres@:bind("mass", "poss").
//     global get_poss_twr_for_pe is get_twr_for_modes_stage_alt@:bind("mass", "poss", stage:number, ship:periapsis).
//     global get_poss_twr_for_pres is get_twr_for_modes_stage_pres@:bind("mass", "poss", stage:number).
//     global get_poss_twr_for_stage_alt is get_twr_for_modes_stage_alt@:bind("mass", "poss").
//     global get_poss_twr_for_stage_pres is get_twr_for_modes_stage_pres@:bind("mass", "poss").

//     //misc
//     global get_twr_at_ap is get_avail_twr_for_ap@.
//     global get_twr_at_pe is get_avail_twr_for_pe@.
//     global get_twr_sl is get_avail_twr_for_pres@:bind(1).
//     global get_twr_vac is get_avail_twr_for_pres@:bind(0).


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