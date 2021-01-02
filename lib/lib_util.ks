@lazyGlobal off.

//Global lexicon of various anonymous function delegates
global utils is lex(
        "checkAltHi"        ,{ parameter _alt. return ship:altitude >= _alt.}
        ,"checkAltLo"       ,{ parameter _alt. return ship:altitude < _alt.}
        ,"checkRadarHi"     ,{ parameter _alt. return alt:radar >= _alt.}
        ,"checkRadarLo"     ,{ parameter _alt. return alt:radar < _alt.}
        ,"getRVal"          ,{ return ship:facing:roll - lookDirUp(ship:facing:forevector, sun:position):roll.}
        ,"timeToGround"     ,{ local ttg to choose 0 if ship:verticalSpeed > 0 else alt:radar / -(ship:verticalSpeed). return ttg. }
        ,"stgFromTag"       ,{ parameter _p. for t in _p:tag:split(".") { if t:startsWith("stgId") { return t:split(":")[1].} return "".}}
        ).

global info is lex(
    "altForSci", lex(
        "Kerbin", 250000,
        "Mun", 60000,
        "Minmus", 30000
        )
    ).


global function get_module_fields {
    parameter m.

    local retObj is lexicon().
    
    for f in m:allFieldNames {
        set retObj[f] to m:getField(f).
    }

    return retObj.
}


// Check functions

    // Checks whether a value falls within a target range
    global function check_value {
        parameter _val,
                  _tgt,
                  _range.

        if _val >= _tgt - _range and _val <= _tgt + _range {
            return true.
        } else {
            return false.
        }
    }


//Part module utils
    // Checks a given module for presence of an event, and does it 
    // if available
    global function do_action {
        parameter _m,       // Module
                _event,   // Event to do if present
                _bit is true.     // The true/false bit for an action.
                                    // Not usually needed, hence the default

        if _m:hasAction(_event) {
            _m:doAction(_event, _bit).
            return true.
        } else {
            return false.
        }
    }


    // Checks a given module for presence of an event, and does it 
    // if available
    global function do_event {
        parameter _m,       // Module
                _event.   // Event to do if present

        if _m:hasEvent(_event) {
            _m:doEvent(_event).
            return true.
        } else {
            return false.
        }
    }


    // Checks a given module for presence of an event, and does it 
    // if available
    global function get_field {
        parameter _m,       // Module
                _field.   // Event to do if present

        if _m:hasField(_field) {
            _m:getField(_field).
            return true.
        } else {
            return false.
        }
    }


//Staging

    // Safe stage. Enforces wait between staging attempts.
    // Also will add delay for cryo upper stages with 
    // deployable nozzles if LH2 is present in the stage
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


    // Staging triggers
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


// Vessel state

    // Checks if the ship is settled with respect to it's intended orientation
    global function shipSettled {
        if steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1 {
            if steeringmanager:rollerror >= -0.1 and steeringmanager:rollerror <= 0.1 {
                return true.
            }
        }

        return false.
    }