//lib for getting mass pivots of a vessel
@lazyGlobal off.

runOncePath("0:/lib/lib_init").


//--
global function get_mass_for_stage_next 
{
    parameter _stg.

    logStr("[get_mass_for_stage_next] _stg: " + _stg).

    local stgMass to 0. 

    for p in ship:parts 
    {
        if p:stage = _stg set stgMass to stgMass + p:mass. 
        if p:stage = _stg + 1 and not (p:isType("engine")) set stgMass to stgMass + p:mass. 
    }

    logStr("[get_mass_for_stage_next]-> return: " + stgMass).

    return stgMass.
}


global function get_mass_for_mode_parts 
{
    parameter _mode,
              _pList.

    logStr("[get_mass_for_mode_parts] _mode: " + _mode + "   _pList: " + _pList:join(";")).    

    local stgMass to 0.
    
    if _mode = "mass" 
    {
        for p in _pList 
        {
            set stgMass to stgMass + p:mass.
        }
    }

    else if _mode = "wet" 
    {
        for p in _pList 
        {
            set stgMass to stgMass + p:wetMass.
        }
    }

    else if _mode = "dry" 
    {
        for p in _pList 
        {
            set stgMass to stgMass + p:dryMass.
        }
    }

    logStr("[get_mass_for_mode_parts]-> return: " + stgMass).

    return stgMass.
}


global function get_res_mass_for_part 
{
    parameter _p,
              _res.

    for r in _p:resources 
    {
        if r:name = _res 
        {
            return r:amount * r:density.
        }
    }

    return 0.
}


// TODO - cache resource data for stages in the global 
// cache file. Needed for rcs (and other) dv / res calcs
global function get_res_mass_for_stg
{
    return false.
}


// Returns the dry mass for the vessel at a given stage.
global function get_dry_mass_at_stage 
{
    parameter _stg.

    if verbose logStr("[get_dry_mass_at_stage] _stg: " + _stg).    

    local dryMass to 0.
    if _stg = stage:nextdecoupler:stage 
    {
        set dryMass to ship:drymass.
    } else 
    {
        for p in ship:parts 
        {
            if p:stage <= _stg set dryMass to dryMass + p:drymass.
        }
    }

    if verbose logStr("[get_dry_mass_at_stage]-> return: " + dryMass).
    return dryMass.
}


// Returns the current mass for the vessel at the provided stage
global function get_mass_at_stage 
{
    parameter _stg.

    if verbose logStr("[get_mass_at_stage] _stg: " + _stg).    

    local stgMass to 0.
    if _stg = stage:nextdecoupler:stage 
    {
        set stgMass to ship:mass.
    } 
    else 
    {
        for p in ship:parts 
        {
            if p:stage <= _stg set stgMass to stgMass + p:mass.
        }
    }

    if verbose logStr("[get_mass_at_stage]-> return: " + stgMass).
    return stgMass.
}


global function get_mass_for_mode_stage 
{
    parameter _mode,
              _stg.

    if verbose logStr("[get_mass_for_mode_stage] _mode: " + _mode + "  _stg: " + _stg).    

    local stgMass to 0.

    if _mode = "mass" 
    {
        for p in ship:parts 
        {
            if p:stage = _stg set stgMass to stgMass + p:mass.
        }
    }

    else if _mode = "wet" 
    {
        for p in ship:parts 
        {
            if p:stage = _stg set stgMass to stgMass + p:wetMass.
        }
    }

    else if _mode = "dry" 
    {
        for p in ship:parts 
        {
            if p:stage = _stg set stgMass to stgMass + p:dryMass.
        }
    }

    if verbose logStr("[get_mass_for_mode_stage]-> return: " + stgMass).

    return stgMass.
}


global function get_stage_mass_obj 
{
    parameter _stg is stage:number.

    if verbose logStr("[get_stage_mass_obj] _stg: " + _stg).

    local pList is ship:partsTaggedPattern("stgId:" + _stg).

    local cMass to 0.
    local dMass to 0.
    local wMass to 0.

    for p in pList 
    {
        set cMass to cMass + p:mass.
        set dMass to dMass + p:dryMass.
        set wMass to wMass + p:wetMass.
    }

    local massObj to lex("cur", cMass, "dry", dMass, "wet", wMass).

    if verbose logStr("[get_stage_mass_obj]-> return <obj>").

    return massObj.
}


// This is an incredibly perf-intensive function and probably not a good idea
global function get_fuel_mass_obj_for_stage 
{
    parameter stg is stage:number.

    local pList is ship:partsTaggedPattern("stgId:" + stg).
    local stgFuelObj is lex().

    for p in pList 
    {
        if p:resources:length > 0 
        {
            for r in p:resources 
            {
                set stgFuelObj[r:name] to r:amount * r:density.
            }
        }
    }

    return stgFuelObj.
}


global function get_ship_mass_at_launch 
{
    local vmass to ship:mass.

    local lplist to ship:partsTaggedPattern("lp.").

    if lplist:length > 0 
    {
        for p in lplist 
        {
            set vmass to vmass - p:mass.
        }
        return vmass.
    }

    else return ship:mass.
}


global function get_ves_mass_at_stage 
{
    parameter _stg.

    if verbose logStr("[get_ves_mass_at_stage] stgId:" + _stg).

    local vMass is 0.

    if _stg = stage:number 
    {
        set vMass to ship:mass.
    } 
    else 
    {
        from { local n to _stg. } until n < -1 step { set n to n - 1. } do 
        {
            for p in ship:parts 
            { 
                if p:tag:matchespattern("stgId:" + n) set vMass to vMass + p:mass.
            }
        }
    }

    if verbose logStr("[get_ves_mass_at_stage]-> return: " + vMass).
    return vMass.
}


global function cache_vessel_mass_obj 
{
    if verbose logStr("[cache_stage_mass_obj] caching").
    local massCache to lex().

    from { local i to stage:number.} until i < -1 step { set i to i - 1.} do
    {
        set massCache[i] to lex().
        set massCache[i]["massObj"] to get_stage_mass_obj(i).
        set massCache[i]["massAt"] to get_ves_mass_at_stage(i).
    }

    writeJson(massCache, "0:/massCache.json").
    if verbose logStr("[cache_vessel_mass_obj]-> return <massCache.json>").

    return massCache.
}