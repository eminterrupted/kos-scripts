@lazyGlobal off.

runOncePath("0:/lib/lib_core").

local usMod to "USAnimateGeneric".

// Takes a part and opens doors on it. 
global function deploy_bay_doors {
    parameter p.

    if p:hasModule(usMod) {
        do_event(usMod, "deploy primary bays").
        do_event(usMod, "deploy secondary bays").
    }
}