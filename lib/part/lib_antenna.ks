@lazyGlobal off.

local mod is "ModuleRTAntenna".

//Activate
global function activate_antenna {
    parameter p.

    p:getModule(mod):doAction("activate", true).
}

global function deactivate_antenna {
    parameter p.

    p:getModule(mod):doAction("deactivate", true).
}

global function get_antenna_fields {
    parameter p.

    local obj is lexicon().
    local m is p:getModule(mod).

    set obj["status"] to m:getField("status").
    set obj["energy"] to m:getField("energy").
    set obj["autoThresh"] to m:getField("auto threshold").
    set obj["activateAt"] to m:getField("activate at ec %").
    set obj["deactivateAt"] to m:getField("deactivate at ec %").
    if m:hasField("target") set obj["target"] to m:getField("target").
    if m:hasField("dish range") set obj["dishRange"] to m:getField("dish range").

    return obj.
}