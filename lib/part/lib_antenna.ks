@lazyGlobal off.

local rtMod to "ModuleRTAntenna".

//Activate
global function activate_omni {
    parameter p.

    local m to p:getModule(rtMod).
    if m:hasEvent("activate") m:doEvent("activate").
}


global function activate_dish {
    parameter p,
              tgt is "Kerbin".
    
    local m is p:getModule(rtMod).
    if m:hasField("target") m:setField("target", tgt).
    if m:hasEvent("activate") m:doEvent("activate").

    return true.
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