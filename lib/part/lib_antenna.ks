@lazyGlobal off.

local rtMod to "ModuleRTAntenna".
local reflectMod to "ModuleDeployableReflector".

//Activate
global function activate_omni {
    parameter p.

    local m to p:getModule(rtMod).
    if m:hasEvent("activate") m:doEvent("activate").
}


global function activate_dish {
    parameter p.
    
    local m is p:getModule(rtMod).
    if m:hasEvent("activate") m:doEvent("activate").

    return true.
}


global function activate_comm_reflector {
    parameter p.

    local m to p:getModule(reflectMod).
    if m:hasEvent("extend reflector") m:doEvent("extend reflector").
}


global function deactivate_dish {
    parameter p.

    local m is p:getModule(rtMod).
    if m:hasEvent("deactivate") m:doEvent("deactivate").
    
    return true.
}


global function deactivate_omni {
    parameter p.

    local m to p:getModule(rtMod).
    if m:hasEvent("deactivate") m:doEvent("deactivate").
}


global function deactivate_comm_reflector {
    parameter p.

    local m to p:getModule(reflectMod).
    if m:hasEvent("retract reflector") m:doEvent("retract reflector").
}

global function get_antenna_fields {
    parameter p.

    local obj to lexicon().
    local m to p:getModule(rtMod).

    for f in m:allFields {
        set f to f:replace("(settable) ", ""):split(",")[0].
        set obj[f] to m:getField(f).
    }

    return obj.
}

global function get_antenna_range {
    parameter p.

    local m to p:getModule(rtMod).
    local range to 0.

    if m:hasField("dish range") set range to m:getField("dish range").
    else if m:hasField("omni range") set range to m:getField("omni range").
    
    local rangeFactor to range:substring(range:length - 2, 2).
    set range to range:substring(0, range:length -2):tonumber.
    if rangeFactor = "Mm" set range to range * 1000000.
    else if rangeFactor = "Gm" set range to range * 1000000000.
    else if rangeFactor = "Km" set range to range * 1000.

    return range.
}


//Dish antenna

global function set_dish_target {
    parameter p,
              pTarget.

    local mod is "ModuleRTAntenna".

    local m is p:getModule(mod).
    m:setField("target",pTarget).
}

global function get_dish_target {
    parameter p.

    local m is p:getModule("ModuleRTAntenna").
    return m:getField("target").
}
//--