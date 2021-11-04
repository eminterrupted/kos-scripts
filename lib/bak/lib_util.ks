@lazyGlobal off.

//#include "0:/boot/bootloader"

// Dependencies
runOncePath("0:/lib/lib_disp").

//-- Variables --//

// Global
global info is lex(
    "altForSci", lex(
        "Kerbin", 250000,
        "Mun", 60000,
        "Minmus", 30000
    )
).

global colors is list(
    red,
    magenta,
    rgb(0.25, 0, 0.75),
    blue,
    cyan,
    green,
    yellow,
    rgb(1, 1, 0),
    white,
    black
).

global colorStr to list(
    "Red",
    "Magenta",
    "Violet",
    "Blue",
    "Cyan",
    "Green",
    "Yellow",
    "Orange",
    "White",
    "Black"
).

// Local
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
global stateFile to dataDisk + "state.json".


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

global function except
{
    parameter msg, 
              errtarget is 0.

    if errTarget = 0 
    {
        disp_msg(msg).
    } else if errtarget = 1
    {
        disp_info(msg).
    } else if errtarget >= 2
    {
        disp_hud(msg, 2).
    }

    return 0 / 1.
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
    return readJson(stateFile):keys:contains(lexKey).
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

// Removes the entire state file
global function util_remove_state
{
    deletePath(stateFile).
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
        else
        {
            set stateObj["runmode"] to 0.
            writeJson(stateObj, stateFile).
        }
    }
    else
    {
        writeJson(lex("runmode", 0), stateFile).
    }
    return 0.
}

// Writes the runmode to disk
global function util_set_runmode
{
    parameter runmode is 0.

    if runmode <> 0 
    {
        if exists(stateFile) 
        {
            local curState to readJson(stateFile).
            set curState["runmode"] to runmode.
            writeJson(curState, stateFile).
        }
        else
        {
            writeJson(lex("runmode", runmode), stateFile).
        }
    }
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

global function util_check_char
{
    parameter checkChar to "0".
    
    if terminal:input:hasChar
    {
        if terminal:input:getChar = checkChar 
        {
            return true.
        }
        else
        {
            return false.
        }
    }
}

global function util_return_char
{
    if terminal:input:hasChar
    {
        return terminal:input:getChar.
    }
    return "".
}

global function util_wait_on_char
{
    local tick to 0.

    until false
    {
        if terminal:input:haschar
        {
            return terminal:input:getChar().
        }
        disp_info2("No Char | Tick: " + tick).
        set tick to choose 0 if tick > 999 else tick + 1.
        wait 0.01.
    }
}

global function util_wait_for_char
{
    parameter keyToCheck to 0, agFlag to true.

    if keyToCheck:typename = "Scalar"
    {
        if keyToCheck = 0 ag10 off.
        else if keyToCheck = 1 ag1 off.
        else if keyToCheck = 2 ag2 off.
        else if keyToCheck = 3 ag3 off.
        else if keyToCheck = 4 ag4 off.
        else if keyToCheck = 5 ag5 off.
        else if keyToCheck = 6 ag6 off.
        else if keyToCheck = 7 ag7 off.
        else if keyToCheck = 8 ag8 off.
        else if keyToCheck = 9 ag9 off.
    }

    until false
    {
        if terminal:input:hasChar
        {
            if terminal:input:getChar = keyToCheck:toString break.
        }
        if agFlag
        {
            if keyToCheck = 0     if ag10 break.
            else if keyToCheck = 1 if ag1 break.
            else if keyToCheck = 2 if ag2 break.
            else if keyToCheck = 3 if ag3 break.
            else if keyToCheck = 4 if ag4 break.
            else if keyToCheck = 5 if ag5 break.
            else if keyToCheck = 6 if ag6 break.
            else if keyToCheck = 7 if ag7 break.
            else if keyToCheck = 8 if ag8 break.
            else if keyToCheck = 9 if ag9 break.
        }    
        wait 0.01.
    }

    if agFlag
    {
        if keyToCheck = 0 ag10 off.
        else if keyToCheck = 1 ag1 off.
        else if keyToCheck = 2 ag2 off.
        else if keyToCheck = 3 ag3 off.
        else if keyToCheck = 4 ag4 off.
        else if keyToCheck = 5 ag5 off.
        else if keyToCheck = 6 ag6 off.
        else if keyToCheck = 7 ag7 off.
        else if keyToCheck = 8 ag8 off.
        else if keyToCheck = 9 ag9 off.
    }
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

global function util_grappling_hook
{
    parameter m is ship:modulesNamed("ModuleGrappleNode")[0],
              mode is "arm". // other values: release, pivot, decouple

    local event to "".
    if mode = "arm" {
        set m to m:part:getModule("ModuleAnimateGeneric").
        set event to "arm".
    }
    else if mode = "release" set event to "release".
    else if mode = "pivot" set event to "free pivot".

    util_do_event(m, event).
}



//#region -- Warp functions -- //
//
// Creates a trigger to warp to a timestamp using AG10
global function util_warp_trigger
{
    parameter tStamp, 
              str is "timestamp",
              buffer is 15.

    set tStamp to tStamp - buffer.
    if time:seconds <= tStamp
    {   
        ag10 off.
        disp_hud("Press 0 to warp to " + str).
        on ag10 
        {
            warpTo(tStamp).
            wait until kuniverse:timewarp:issettled.
            ag10 off.
        }
    }
}

// Smooths out a warp down by either altitude or timestamp
global function util_warp_down_to_alt {
    parameter tgtAlt.
    
    if ship:altitude <= tgtAlt * 1.01 set warp to 0.
    else if ship:altitude <= tgtAlt * 1.05 set warp to 1.
    else if ship:altitude <= tgtAlt * 1.20 set warp to 2.
    else if ship:altitude <= tgtAlt * 1.35 set warp to 3.
    else if ship:altitude <= tgtAlt * 3 set warp to 4.
    else if ship:altitude <= tgtAlt * 5 set warp to 5.
    else if ship:altitude <= tgtAlt * 20 set warp to 6.
    else set warp to 7.
}
//#endregion

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
