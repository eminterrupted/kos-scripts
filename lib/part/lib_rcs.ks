@lazyGlobal off.

local rcsMod is "ModuleRCSFX".
local actShow is "show actuation toggles".
local actHide is "hide actuation toggles".
local actTog is "toggle rcs".

global function rcs_activate {
    parameter pList is ship:modulesNamed(rcsMod).

    for p in pList {
       if p:isType("Part") set p to p:getModule(rcsMod).
       if not p:getField("rcs")  p:doAction(actTog, true).
    }

    rcs on.
}

global function rcs_deactivate {
    parameter pList is ship:modulesNamed(rcsMod).

    for p in pList {
        if p:isType("Part") set p to p:getModule(rcsMod).
        if p:getField("rcs") p:doAction(actTog, true).
    }

    rcs off.
}

global function rcs_tog_act {
    parameter p,            // rcs [part or module]
              dir,          // which actuators to toggle. Accepts ";" delimited string, see below for enum
              tog is true.  // true = on, false = off

    if p:isType("Part") set p to p:getModule(rcsMod).
    if p:hasEvent(actShow) p:doEvent(actShow).

    for d in dir:split(";") {
        if d = "y" p:setField("yaw", tog).
        else if d = "p" p:setField("pitch", tog).
        else if d = "r" p:setField("roll", tog).
        else if d = "p/s" p:setField("port/stbd", tog).
        else if d = "d/v" p:setField("dorsal/ventral", tog).
        else if d = "f/a" p:setField("fore/aft", tog).
        else if d = "fThr" p:setField("fore by throttle", tog).
    }

    return rcs_obj(p).
}

global function rcs_obj {
    parameter p.

    local rcsObj is lex().

    if p:isType("Part") set p to p:getModule(rcsMod).
    if p:hasEvent(actShow) p:doEvent(actShow).

    set rcsObj["name"] to p:name.

    for f in p:allfields {
        set f to f:split(",")[0]:replace("(settable) ","").
        set rcsObj[f] to p:getField(f).
    }

    if p:hasEvent(actHide) p:doEvent(actHide).
    return lex(p:cid, rcsObj).
}

global function rcs_thrust_limit {
    parameter p,
              limit is 100.

    local field is "thrust limiter".

    if p:isType("Part") set p to p:getModule(rcsMod).
    if p:hasField(field) p:setField(field, limit).

    return p:getField(field).
}

global function rcs_translate_vec {
    parameter tVec. // Format: v(starboard[-1, 1], top[-1, 1], fore[1, 1])

    set ship:control:translation to tVec.
}