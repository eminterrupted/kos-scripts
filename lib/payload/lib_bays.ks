@lazyGlobal off.

runOncePath("0:/lib/lib_util").

local usMod to "USAnimateGeneric".

// Takes a part and opens doors on it. 
global function deploy_bay_doors 
{
    parameter p.

    if p:hasModule(usMod) 
    {
        local m to p:getModule(usMod).
        do_event(m, "deploy primary bays").
        do_event(m, "deploy secondary bays").
        wait 3. // wait for bay door to open
    }
}