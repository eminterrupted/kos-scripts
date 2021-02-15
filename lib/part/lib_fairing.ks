@lazyGlobal off.

local dcMod is "ProceduralFairingDecoupler".
local pfMod is "ModuleProceduralFairing".

global function arm_pl_fairings 
{
    parameter base is ship:partsTaggedPattern("pl.base")[0],
              palt is 72500.  

    local chList is list().
    
    for c in base:children 
    {
        if c:tag:contains("fairing"). chList:add(c).
    }

    when ship:altitude >= palt then 
    {
        for p in chList 
        {
            jettison_fairing(p).
        }
    }
}

global function jettison_fairing 
{
    parameter p.

    if p:hasModule(pfMod) 
    {
        do_event(p:getModule(pfMod), "deploy").
    }
    else if p:hasModule(dcMod) 
    {
        local m is p:getModule(dcMod).
        local eventResult to do_event(m, "jettison fairing").
        if not eventResult
        {
            do_event(m, "jettison").
        }
    }
}