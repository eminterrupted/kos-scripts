@lazyGlobal off.

runOncePath("0:/lib/lib_util").

local solMod to "ModuleDeployableSolarPanel".

//Activate
global function activate_solar {
    parameter p.

    return do_event(p:getModule(solMod), "extend solar panel").
}


global function deactivate_solar {
    parameter p.
    
    return do_event(p:getModule(solMod), "retract solar panel").
}


global function toggle_solar {
    parameter p.

    return do_event(p:getModule(solMod), "toggle solar panel").
}