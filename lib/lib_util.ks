@lazyGlobal off.

//#include "0:/boot/bootloader"

//-- Variables --//
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
local stateFile to dataDisk + "state.json".

//-- Global Functions --//

// -- Generic functions -- //
//
// Creates a breakpoint
global function breakpoint
{
    print "* Press any key to continue *" at (10, terminal:height - 2).
    terminal:input:getChar().
    print "                             " at (10, terminal:height - 2).
}

global function util_play_sfx 
{
    parameter sfxId to 0.

    if sfxId = 0 set sfxId to readJson("0:/sfx/ZeldaUnlock.json").
    local v0 to getVoice(0).
    from { local idx to 0.} until idx = sfxId:length step { set idx to idx + 1.} do
    {
        v0:play(sfxId[idx]).
        wait 0.05.
    }
}



// -- Vessel State functions -- //
//
// State cache
// Caches an arbitrary bit of data in the state file
global function util_cache_state
{
    parameter lexKey,
              lexVal.

    local stateObj to lex().
    if exists(stateFile) 
    {
        set stateObj to readJson(stateFile).
    }
    set stateObj[lexKey] to lexVal.
    writeJson(stateObj, stateFile).
    return stateObj[lexKey].
}

global function util_peek_cache
{
    parameter lexKey.

    local stateObj to lex().
    if exists(stateFile)
    {
        set stateObj to readJson(stateFile).
    }
    if stateObj:hasKey(lexKey)
    {
        return true.
    }
    else 
    {
        return false.
    }
}

global function util_read_cache
{
    parameter lexKey.

    if exists(stateFile)
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey(lexKey) return stateObj[lexKey].
    }
    return false.
}

// Clears a value from the state file
global function util_clear_cache_key
{
    parameter lexKey.

    if exists(stateFile) 
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey(lexKey)
        {
            stateObj:remove(lexKey).
            writeJson(stateObj, stateFile).
        }
    }
}

// Resets the entire state file
global function util_reset_state
{
    writeJson(lex(), stateFile).
}

// Runmode
// Gets the runmode from disk if exists, else returns 0
global function util_init_runmode
{
    if exists(stateFile) 
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey("runmode")
        {
            return stateObj["runmode"].
        }
    }
    return 0.
}

// Writes the runmode to disk
global function util_set_runmode
{
    parameter runmode is 0.

    if runmode <> 0 writeJson(lex("runmode", runmode), stateFile).
    else if exists(stateFile) deletePath(stateFile).

    return runmode.
}


// -- List functions -- //
//
// Sorts a list of parts by stage
// Possible sortDir values: asc, desc
global function util_order_list_by_stage
{
    parameter inList,
              sortDir is "desc".

    local outList    to list().
    local startCount to choose -1 if sortDir = "asc" else stage:number.
    local endCount   to choose stage:number if sortDir = "asc" else -2.

    from { local c to startCount.} until c = endCount step { set c to list_step(c, sortDir). } do
    {
        for p in inList 
        {
            if p:stage = c
            {
                outList:add(p).
            }
        }
    }
    return outList.
}


// -- Check functions -- //
//
// Function for use in maneuver delegates
global function util_check_del 
{
    parameter checkType,
              rangeLo,
              rangeHi.
    
    local val to 0.

    if checkType = "ap"         set val to ship:apoapsis.
    else if checkType = "pe"    set val to ship:periapsis.
    else if checkType = "inc"   set val to ship:orbit:inclination.

    if val >= rangeLo and val <= rangeHi return true.
    else return false.
}

// Checks if ship EC is high enough
global function util_check_power
{
    parameter checkType is "sample".

    local charge to 0.
    local draw   to 0.

    if checkType = "sample" 
    {
        set charge to ship:resources:ec.
        wait 0.25.
        set draw to charge - ship:resources:ec / 0.25.
    }

    print draw.

    return false.
}

// Checks if a value is above/below the range bounds given
global function util_check_range
{
    parameter val,
              rangeLo,
              rangeHi.

    if val >= rangeLo and val <= rangeHi return true.
    else return false.
}

// Checks if a value is between a range centered around 0.
global function util_check_value
{
    parameter val,
              valRange.

    if val >= -(valRange) and val <= valRange return true.
    else return false.
}


// -- Part modules -- //
//
// Checks for an action and executes if found
global function util_do_action
{
    parameter m, 
              action, 
              state is true.

    if m:hasAction(action)
    {
        m:doAction(action, state).
        return true.
    }
    else
    {
        return false.
    }
}

// Checks for an event and executes if found
global function util_do_event
{
    parameter m, 
              event.

    if m:hasEvent(event)
    {
        m:doEvent(event).
        return true.
    }
    else
    {
        return false.
    }
}

// Searches a module for events / actions
global function util_event_from_module
{
    parameter m,
              event,
              searchActions to true.

    for e in m:allEvents
    {
        if e:contains(event)
        {
            return e:replace("(callable) ", ""):replace(", is KSPEvent", "").
        }
    }

    if searchActions
    {
        for a in m:allActions
        {
            if a:contains(event)
            {
                return a:replace("(callable) ", ""):replace(", is KSPEvent", "").
            }
        }
    }
    return "".
}

// Deploys US Bay Doors
global function util_us_bay_toggle
{
    parameter bay,
              doors is "all".

    local aniMod to "USAnimateGeneric".
    local pEvent to "deploy primary bays".
    local sEvent to "deploy secondary bays".

    if doors = "all" or doors = "primary"
    {
        util_do_event(bay:getModule(aniMod), pEvent).
    }
    if doors = "all" or doors = "secondary"
    {
        util_do_event(bay:getModule(aniMod), sEvent).
    }
}

global function util_capacitor_discharge_trigger
{
    local ecMon to 0.
    local resList to list().
    list resources in resList.
    for res in resList
    {
        if res:name = "ElectricCharge" lock ecMon to res:amount / res:capacity.
    }

    when ecMon <= 0.05 then
    {
        for cap in ship:partsDubbedPattern("capacitor")
        {
            local m to cap:getModule("DischargeCapacitor").
            util_do_event(m, "disable recharge").
            util_do_event(m, "discharge capacitor").
            until ecMon >= 0.99 or cap:resources[0]:amount <= 0.1
            {
                wait 0.01.
            }
        }
    }
}



// -- Warp functions -- //
//
// Creates a trigger to warp to a timestamp using AG10
global function util_warp_trigger
{
    parameter tStamp, str is "timestamp".

    set tStamp to tStamp - 15.
    if time:seconds <= tStamp
    {   
        ag10 off.
        hudtext("Press 0 to warp to " + str, 15, 2, 20, green, false).
        on ag10 
        {
            warpTo(tStamp).
            wait until kuniverse:timewarp:issettled.
            ag10 off.
        }
    }
}

// Warps to a given altitude
global function util_warp_altitude
{
    parameter tgtAlt.

    local dAlt to ship:altitude.
    wait 2.5.
    local s to (tgtAlt - ship:altitude) / ((ship:altitude - dAlt) / 2).
        
    local ts to time:seconds + abs(s).
    util_warp_trigger(ts).
}


// -- Local functions -- //
//
// Helper function for from loop in list sorting. 
local function list_step
{
    parameter c,
              sortDir.

    if sortDir = "desc" return c - 1.
    else return c + 1.
}
