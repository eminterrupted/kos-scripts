//lib for getting mass pivots of a vessel
@lazyGlobal off.

//Delegates    
    //Mass by stage
    global get_dry_mass_at_stage to get_mass_at_mode_stage@:bind("dry").
    //global get_dry_mass_for_stage to get_mass_for_mode_stage@:bind("dry").
    global get_mass_at_stage to get_mass_at_mode_stage@:bind("mass").
    //global get_mass_for_stage to get_mass_for_mode_stage@:bind("mass").
    //global get_wet_mass_at_stage to get_mass_at_mode_stage@:bind("wet").
    //global get_wet_mass_for_stage to get_mass_for_mode_stage@:bind("wet").


    //Mass by parts list
    //global get_dry_mass to get_mass_for_mode_parts@:bind("dry").
    //global get_mass to get_mass_for_mode_parts@:bind("mass").
    //global get_wet_mass to get_mass_for_mode_parts@:bind("wet").

//--
global function get_mass_for_stage_next {
    parameter pStage.

    local stgMass to 0. 

    for p in ship:parts {
        if p:stage = pStage set stgMass to stgMass + p:mass. 
        if p:stage = pStage + 1 and not (p:isType("engine")) set stgMass to stgMass + p:mass. 
    }

    return stgMass.
}


global function get_mass_for_mode_parts {
    parameter pMode,
              pList.

    local stageMass to 0.
    
    if pMode = "mass" {
        for p in pList {
            set stageMass to stageMass + p:mass.
        }
    }

    else if pMode = "wet" {
        for p in pList {
            set stageMass to stageMass + p:wetMass.
        }
    }

    else if pMode = "dry" {
        for p in pList {
            set stageMass to stageMass + p:dryMass.
        }
    }

    return stageMass.
}


// global function get_mass_obj_at_stage {
//     parameter pStage.

//     return true.
// }



global function get_mass_at_mode_stage {
    parameter pMode,
              pStage.

    local stageMass to 0.
    
    if pMode = "mass" {
        for p in ship:parts {
            if p:stage <= pStage set stageMass to stageMass + p:mass.
        }
    }

    else if pMode = "wet" {
        for p in ship:parts {
            if p:stage <= pStage set stageMass to stageMass + p:wetMass.
        }
    }

    else if pMode = "dry" {
        for p in ship:parts {
            if p:stage <= pStage set stageMass to stageMass + p:dryMass.
        }
    }

    return stageMass.
}


global function get_mass_for_mode_stage {
    parameter pMode,
              pStage.

    local stageMass to 0.

    if pMode = "mass" {
        for p in ship:parts {
            if p:stage = pStage set stageMass to stageMass + p:mass.
        }
    }

    else if pMode = "wet" {
        for p in ship:parts {
            if p:stage = pStage set stageMass to stageMass + p:wetMass.
        }
    }

    else if pMode = "dry" {
        for p in ship:parts {
            if p:stage = pStage set stageMass to stageMass + p:dryMass.
        }
    }

    return stageMass.
}


global function get_stage_mass_obj {
    parameter stg is stage:number.

    local pList is ship:partsTaggedPattern("stgId:" + stg).


    local cMass to 0.
    local dMass to 0.
    local wMass to 0.

    for p in pList {
        if not p:tag:startswith("lp") {
            set cMass to cMass + p:mass.
            set dMass to dMass + p:dryMass.
            set wMass to wMass + p:wetMass.
        }
    }

    return lex("cur", cMass, "dry", dMass, "wet", wMass).
}


global function get_ship_mass_at_launch {
    local vmass to ship:mass.

    local lplist to ship:partsTaggedPattern("lp.").

    if lplist:length > 0 {
        for p in lplist {
            set vmass to vmass - p:mass.
        }
        return vmass.
    }

    else return ship:mass.
}


global function get_vmass_at_stg {
    parameter stgId.

    logStr("get_vmass_at_stg").
    logStr("stgId: " + stgId).

    local vmass is 0.
    from { local n to stgId. } until n < -1 step { set n to n - 1. } do {
        for p in ship:parts { 
            if p:tag:matchespattern("stgId:" + n) set vmass to vmass + p:mass.
        }
    }

    logStr("return vmass[" + vmass + "]").
    return vmass.
}