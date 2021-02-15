@lazyGlobal off.

local rcsMod is "ModuleRCSFX".
local actShow is "show actuation toggles".
local actHide is "hide actuation toggles".
local actTog is "toggle rcs".


global function get_rcs_exh_vel 
{
    parameter p.

    return constant:g0 * p:getModule("ModuleRCSFX"):getField("rcs isp").
}


global function rcs_activate 
{
    parameter pList is ship:modulesNamed(rcsMod).

    for p in pList 
    {
       if p:isType("Part") 
       {
           set p to p:getModule(rcsMod).
       }
       
       if not p:getField("rcs") 
       {
           p:doAction(actTog, true).
       }
    }
}

global function rcs_deactivate 
{
    parameter pList is ship:modulesNamed(rcsMod).

    for p in pList 
    {
        if p:isType("Part") 
        {
            set p to p:getModule(rcsMod).
        }
        
        if p:getField("rcs") 
        {
            p:doAction(actTog, true).
        }
    }
}

global function rcs_tog_act 
{
    parameter p,            // rcs part
              dir,          // which actuators to toggle. 
                            // Accepts ";" delimited string, 
                            // see below for enum
              tog is true.  // true = on, false = off

    local m to p:getModule(rcsMod).
    if m:hasEvent(actShow) m:doEvent(actShow).

    for d in dir:split(";") 
    {
        if d = "y" m:setField("yaw", tog).
        else if d = "p" m:setField("pitch", tog).
        else if d = "r" m:setField("roll", tog).
        else if d = "p/s" m:setField("port/stbd", tog).
        else if d = "d/v" m:setField("dorsal/ventral", tog).
        else if d = "f/a" m:setField("fore/aft", tog).
        else if d = "fThr" m:setField("fore by throttle", tog).
    }

    return rcs_obj(p).
}

// Returns an rcs object for reference as a group later
global function rcs_obj 
{
    parameter p.

    local rcsObj is lex().

    local m to p:getModule(rcsMod).
    do_event(m, actShow).

    set rcsObj["name"] to p:name.

    for f in m:allfields
    {
        set f to f:split(",")[0]:replace("(settable) ","").
        set rcsObj[f] to m:getField(f).
    }

    do_event(m, actHide).
    return lex(p:cid, rcsObj).
}

// Sets the rcs thrust limiter
global function rcs_thrust_limit 
{
    parameter p,
              limit is 100.

    local field is "thrust limiter".

    local m to p:getModule(rcsMod).
    set_field(m, field, limit).
}

// Not entirely sure
global function rcs_translate_vec 
{
    parameter tVec. // Format: v(starboard[-1, 1], top[-1, 1], fore[1, 1])

    set ship:control:translation to tVec.
}