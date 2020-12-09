//Set vessel configurations
@lazyGlobal off. 

runOncePath("0:/lib/lib_init.ks").

//Waits until vessel is safe to stage, then stages
global function safe_stage {
    
    wait 0.5.
    logStr("Staging").

    until false {
        until stage:ready {   
            wait 0.01.
        }

        if stage:ready {
            stage.
            wait 1.
            break.
        }
    }

    for r in stage:resources {
        if r:name = "lqdHydrogen" {
            if r:amount > 0 wait 3.5.
        }
    }
}

global function staging_triggers {

    //For solid fuel launch boosters
    // if ship:partsTaggedPattern("eng.solid"):length > 0 {
    //     when ship:solidfuel < 0.1 and throttle > 0 then {
    //         safe_stage().
    //     }
    // }

    // For liquid fueled engines. 
    when ship:availableThrust < 0.1 and throttle > 0 then {
        safe_stage().
        preserve.
    }
}


global function arm_chutes {
    parameter pList is ship:parts.

    local chuteMod is "RealChuteModule".

    for p in pList {
        if p:hasModule(chuteMod) {
            local m is p:getModule(chuteMod).
            if m:hasEvent("arm parachute") m:doEvent("arm parachute").
        }
    }
}


global function get_solar_exp {
    local solList is ship:partsDubbedPattern("solar").
    local exp is 0.
    local mod is "ModuleDeployableSolarPanel".

    for p in solList {
        local m is p:getModule(mod).
        set exp to exp + m:getField("sun exposure").        
    }

    if not (exp = 0) {
        return exp / solList:length.
    } else {
        return 0.
    }
}

// global function warp_to_longitude {
//     parameter lng.

//     return true.
// }