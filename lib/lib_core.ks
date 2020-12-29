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



//
//-- Functions --//
//

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


// Get stage parts

    // Get parts for a specific stage
    global function parts_for_stage {
        parameter _stgNum.

        local pList is list().

        for p in ship:parts {
            if utils:stgFromTag(p) = _stgNum {
                pList:add(p).
            }
        }

        return pList.
    }

    // Get parts starting at a specific stage and up
    global function parts_at_stage {
        parameter _stgNum.

        local pList is list().

        for p in ship:parts {
            if utils:stgFromTag(p) <= _stgNum {
                pList:add(p).
            }
        }

        return pList.
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



global function time_to_alt_next {
    parameter _alt.

    if ship:altitude < _alt {
        return _alt - ship:altitude / ship:verticalSpeed.
    } else {
        return ship:altitude - _alt / ship:verticalSpeed.
    }
}


// Terminal
    
    // Waits for keypress with msg on screen
    global function breakpoint {
        print ("*** BREAKPOINT: Press any key ***") at (10, 55).
        terminal:input:getchar().
        print ("                                 ") at (10, 55).
    }


// Wait functions
    // Waits until the ship is settled
    global function wait_unti_ship_settled {
        until shipSettled {
            update_display().
        }
    }

    // Checks if the ship is settled with respect to it's intended orientation
    global function shipSettled {
        if steeringmanager:angleerror >= -0.05 and steeringmanager:angleerror <= 0.05 {
            if steeringmanager:rollerror >= -0.05 and steeringmanager:rollerror <= 0.05 {
                return true.
            }
        }

        return false.
    }


    // Waits until a given timestamp, updates the display
    global function wait_with_display {
        parameter tStamp,
                name is "Wait".

        lock steering to lookDirUp(ship:facing:forevector, sun:position).

        until time:seconds >= tStamp {
            update_display().
            disp_timer(tStamp, name).
        }

        disp_clear_block("timer").
    }
