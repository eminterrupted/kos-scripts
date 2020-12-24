//Set vessel configurations
@lazyGlobal off. 

runOncePath("0:/lib/lib_init").

//Global lexicon of various anonymous function delegates
global utils is lex(
        "checkAltHi"        ,{ parameter _alt. return ship:altitude >= _alt.}
        ,"checkAltLo"       ,{ parameter _alt. return ship:altitude < _alt.}
        ,"checkRadarHi"     ,{ parameter _alt. return alt:radar >= _alt.}
        ,"checkRadarLo"     ,{ parameter _alt. return alt:radar < _alt.}
        ,"getRVal"          ,{ return ship:facing:roll - lookDirUp(ship:facing:forevector, sun:position):roll.}
        ,"timeToAlt"        ,{ parameter _alt. return time_to_alt_next(_alt).}
        ,"timeToGround"     ,{ return alt:radar / ship:verticalSpeed.}
        ,"stgFromTag"       ,{ parameter _p. for t in p:tag:split(".") { if t:startsWith("stgId") { return t:split(":")[1].} return "".}}
        ).

global info is lex(
    "altForSci", lex(
        "Kerbin", 250000,
        "Mun", 60000,
        "Minmus", 30000
        )
    ).



global function time_to_alt_next {
    parameter _alt.

    if ship:altitude < _alt {
        return _alt - ship:altitude / ship:verticalSpeed.
    } else {
        return ship:altitude - _alt / ship:verticalSpeed.
    }
}


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

    //One time trigger for solid fuel launch boosters
    if ship:partsTaggedPattern("eng.solid"):length > 0 {
        when stage:solidfuel < 0.1 and throttle > 0 then {
            safe_stage().
        }
    }

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
