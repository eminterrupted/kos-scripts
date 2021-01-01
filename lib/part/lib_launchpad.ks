@lazyGlobal off.

//local clampMod is "launchClamp".
local genMod is "ModuleGenerator".
local aniMod is "ModuleAnimateGeneric".

//Power, fueling
global function mlp_gen_on {
    local event to "activate generator".
    do_pad_event@:call(genMod, event).
}

global function mlp_gen_off {
    local event to "shutdown generator".
    do_pad_event@:call(genMod, event).
}

global function mlp_fuel_on {
    local event is "start fueling".
    do_pad_event@:call(genMod, event).
}

global function mlp_fuel_off {
    local event is "stop fueling".
    do_pad_event@:call(genMod, event).
}


//Fallback tower
global function mlp_fallback_open_clamp {
    local event is "open upper clamp".
    do_pad_event@:call(aniMod, event).
}

global function mlp_fallback_partial {
    local event is "partial retract tower step 1".
    do_pad_event@:call(aniMod, event).
}

global function mlp_fallback_full {
    local event is "full retract tower step 2".
    do_pad_event@:call(aniMod, event).
}


//Holddowns
global function mlp_retract_holddown {
    local armEvent is "retract arm".
    local boltEvent is "retract bolt".

    if check_pad_event@:call(aniMod, armEvent) do_pad_event@:call(aniMod, armEvent).
    if check_pad_event@:call(aniMod, boltEvent) do_pad_event@:call(aniMod, boltEvent).
}


//Swing arms
global function mlp_retract_crewarm {
    local armEvent is "retract crew arm".

    do_pad_event@:call(aniMod, armEvent).
}

global function mlp_retract_swingarm {
    local armEvent is "retract arm right".

    do_pad_event@:call(aniMod, armEvent).
}


//Umbilicals
global function mlp_drop_umbilical {
    local event is "drop umbilical".
    do_pad_event@:call(aniMod, event).
}


//Delegate functions
local function check_pad_event {
    parameter mod, event.

    for m in ship:modulesNamed(mod) {
        if m:part:tag:contains("mlp") {
            if m:hasEvent(event) return true.
        }
    }

    return false.
}

local function do_pad_event {
    parameter mod, event.

    for m in ship:modulesNamed(mod) {
        if m:part:tag:contains("mlp") {
            if m:hasEvent(event) m:doEvent(event).
        }
    }
}