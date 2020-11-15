@lazyGlobal off.

local mod to "ModuleRTAntenna".

//Activate
global function activate_omni {
    parameter p.

    local m to p:getModule(mod).
    if m:hasEvent("activate") m:doEvent("activate").
}


global function activate_dish {
    return true.
}


global function deactivate_dish {
    return true.
}


global function deactivate_omni {
    parameter p.

    local m to p:getModule(mod).
    if m:hasEvent("deactivate") m:doEvent("deactivate").
}


global function get_antenna_fields {
    parameter p.

    local obj to lexicon().
    local m to p:getModule(mod).

    for f in m:allFields {
        set f to f:replace("(settable) ", ""):split(",")[0].
        set obj[f] to m:getField(f).
    }

    return obj.
}