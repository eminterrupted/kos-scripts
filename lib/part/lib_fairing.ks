@lazyGlobal off.

local fgMod is "ModuleProceduralFairing".
local dcMod is "ProceduralFairingDecoupler".

global function arm_pl_fairings {
    parameter base is ship:partsTaggedPattern("pl.base")[0],
              palt is 72500.  

    local chList is list().
    
    for c in base:children {
        if c:tag:contains("fairing"). chList:add(c).
    }

    when ship:altitude >= palt then {
        for p in chList {
            jet_fairing(p).
        }
    }
}

global function jet_fairing {
    parameter p.

    if p:hasModule(fgMod) {
        local m is p:getModule(fgMod).
        if m:hasEvent("deploy") m:doEvent("deploy").
    }

    else if p:hasModule(dcMod) {
        local m is p:getModule(dcMod).
        if m:hasEvent("jettison fairing") m:doEvent("jettison fairing").
        else if m:hasEvent("jettison") m:doEvent("jettison").
    }
}