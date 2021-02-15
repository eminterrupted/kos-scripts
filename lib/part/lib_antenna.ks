@lazyGlobal off.

local commMod to "ModuleRTAntenna".

//Activate / Deactivate
global function activate_antenna 
{
    parameter p.
    do_event(p:getModule(commMod), "activate"). 
}

global function deactivate_antenna
{
    parameter p.
    do_event(p:getModule(commMod), "deactivate").
}


global function get_antenna_fields {
    parameter p.

    local obj to lexicon().
    local m to p:getModule(commMod).

    for f in m:allFields {
        set f to f:replace("(settable) ", ""):split(",")[0].
        set obj[f] to m:getField(f).
    }

    return obj.
}

global function get_antenna_range {
    parameter p.

    local m to p:getModule(commMod).
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