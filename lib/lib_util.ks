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


// Math functions
    // Calculates the eccentricity of given ap, pe, and planet
    global function calc_ecc {
        parameter _ap,
                _pe,
                _body is ship:body.

        if _body:typeName <> "Body" set _body to Body(_body).
        
        return (_ap + _body:radius) - (_pe + _body:radius) / (_ap + _pe + (_body:radius * 2)).
    }

    // Returns the desired apoapsis given a known periapsis and
    // eccentricity
    global function get_ap_for_pe_ecc {
        parameter _pe,
                  _ecc,
                  _body is ship:body.

        local sma   to (_pe + _body:radius) / (1 - _ecc).
        local rA    to sma * (1 + _ecc).

        return rA - _body:radius.
    }

    // Returns the desired periapsis given a known apoapsis and
    // eccentricity
    global function get_pe_for_ap_ecc {
        parameter _ap,
                  _ecc,
                  _body is ship:body.

        local sma   to (_ap + _body:radius) / (1 + _ecc).
        local rP    to sma * (1 - _ecc).

        return rP - _body:radius.
    }


//Part module utils
    // Checks a given module for presence of an event, and does it 
    // if available
    global function do_action 
    {
        parameter _m,       // Module
                _event,   // Event to do if present
                _bit is true.     // The true/false bit for an action.
                                    // Not usually needed, hence the default

        if _m:hasAction(_event) 
        {
            _m:doAction(_event, _bit).
            return true.
        } 
        else 
        {
            return false.
        }
    }


    // Checks a given module for presence of an event, and does it 
    // if available
    global function do_event 
    {
        parameter _m,       // Module
                _event.   // Event to do if present

        if _m:hasEvent(_event) 
        {
            _m:doEvent(_event).
            return true.
        } 
        else 
        {
            return false.
        }
    }


    // Checks a given module for presence of a field, and 
    // returns it if present, false if not 
    global function get_field 
    {
        parameter _m,
                  _field.

        if _m:hasField(_field) 
        {
            return _m:getField(_field).
        } 
        else 
        {
            return false.
        }
    }

    global function set_field
    {
        parameter _m,
                  _field,
                  _val.

        if _m:hasField(_field)
        {
            _m:setField(_field, _val).
            return true.
        }
        else
        {
            return false.
        }
    }

    // Returns an obj with all fields for a given module
    global function get_module_fields 
    {
    parameter m.

    local retObj is lexicon().
    
    for f in m:allFieldNames 
    {
        set retObj[f] to m:getField(f).
    }

    return retObj.
}


//Staging

    // Safe stage. Enforces wait between staging attempts.
    // Also will add delay for cryo upper stages with 
    // deployable nozzles if LH2 is present in the stage
    global function safe_stage 
    {
        
        wait 0.5.
        logStr("Staging").

        until false {
            until stage:ready 
            {   
                wait 0.01.
            }

            if stage:ready 
            {
                stage.
                wait 0.5.
                break.
            }
        }

        if stage:resourcesLex:lqdHydrogen:amount > 0 
        {
            wait 5.
        }

        if ship:partsTaggedPattern("sep.*.stgId:" + stage:number):length > 0 
        {
            wait 0.5. 
            stage.
        }
        
        // for r in stage:resources {
        //     if r:name = "lqdHydrogen" {
        //         if r:amount > 0 wait 5.
        //     }
        // }
    }


    // Staging triggers
    global function staging_triggers 
    {

        //One time trigger for solid fuel launch boosters
        if ship:partsTaggedPattern("eng.solid"):length > 0 
        {
            when stage:solidfuel < 0.1 and throttle > 0 then 
            {
                safe_stage().
            }
        }

        // For liquid fueled engines.
        when ship:availableThrust < 0.1 and throttle > 0 then 
        {
            safe_stage().
            preserve.
        }
    }


// Vessel state

    // Checks if the ship is facing within 0.1 degrees of the target vector direction
    global function shipFacing 
    {
        local _acc to 1.
        if vAng(ship:facing:forevector, steering:vector) <= _acc 
        {
            print "                 " at (2, terminal:height - 10).
            return true.
        }
        else 
        {
            print "shipFacing: false" at (2, terminal:height - 10).
            return false.
        }
    }

    // Checks if the ship is settled with respect to it's intended orientation
    global function shipSettled 
    {
        if steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1 
        {
            if steeringmanager:rollerror >= -0.1 and steeringmanager:rollerror <= 0.1 
            {
                return true.
            }
        }

        return false.
    }


    // Gets the time until impact with the ground, with optional margin
    // From CheersKevin - https://www.youtube.com/watch?v=-goK27y6Xd4&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=16
    global function time_to_impact 
    {
        parameter margin is 0.

        local d is alt:radar - margin.
        local v is -(ship:verticalspeed).
        local g is ship:body:mu / ship:body:radius^2. 

        return (sqrt(v^2 + 2 * g * d) - v) / g.
    }