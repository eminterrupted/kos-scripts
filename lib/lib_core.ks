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
            wait 0.75.
            break.
        }
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


global function warp_to_alt {
    parameter pAlt.

    //local altWarpMode to choose 1 if ship:altitude >= pAlt else 0.

    if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:issettled {
        set kuniverse:timewarp:mode to choose "RAILS" if ship:altitude > body:atm:height else "PHYSICS".
    }

    if ship:altitude >= pAlt * 15 {
        if kuniverse:timewarp:warp <> 5 {
            set kuniverse:timewarp:warp to 5.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 5 {
        if kuniverse:timewarp:warp <> 4 {
            set kuniverse:timewarp:warp to 4.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 2.5 {
        if kuniverse:timewarp:warp <> 3 {
            set kuniverse:timewarp:warp to 3.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 1.25 {
        if kuniverse:timewarp:warp <> 2 {
            set kuniverse:timewarp:warp to 2.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 1.075 {
        if kuniverse:timewarp:warp <> 1 {
            set kuniverse:timewarp:warp to 1.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude > pAlt {
        if kuniverse:timewarp:warp > 0 kuniverse:timewarp:cancelwarp().
    }
}

// global function warp_to_longitude {
//     parameter lng.

//     return true.
// }