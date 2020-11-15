//lib for getting mass pivots of a vessel
@lazyGlobal off.

//Delegates    
    //Mass by stage
    //global get_dry_mass_at_stage to get_mass_at_mode_stage@:bind("dry").
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