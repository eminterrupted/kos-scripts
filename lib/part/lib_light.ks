@lazyGlobal off.

//Set RGB Values
global function set_kos_rgb {
    parameter p,
            r is 0.45,
            g is 0.35,
            b is 0.75.

    local m is p:getModule("kOSLightModule").

    m:setField("light r", r).
    m:setField("light g", g).
    m:setField("light b", b).
}

global function tog_cherry_light {
    parameter p,
              mode is true.

    local m is p:getModule("ModuleLight").
    if mode {
        if m:hasEvent("lights on") m:doEvent("lights on").
    }
    else if m:hasEvent("lights off") m:doEvent("lights off").
}