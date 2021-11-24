@lazyGlobal off.

// Dependencies

// *~ Variables ~* //
//#region

// -- Global
// #region
global BodyInfo to lex(
    "altForSci", lex(
        "Kerbin", 250000,
        "Mun", 60000,
        "Minmus", 30000
    )
).

global ColorLex to lex(
    "Red", red
    ,"Magenta", magenta
    ,"Violet", rgb(0.25, 0, 0.75)
    ,"Blue", blue
    ,"Cyan", cyan
    ,"Green", green
    ,"Yellow", yellow
    ,"Orange", rgb(1, 1, 0)
    ,"White", white
    ,"Black", black
).
// #endregion

// -- Local
// #region
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
global StateFile to dataDisk + "state.json".
// #endregion
//#endregion


// *~ Functions ~* //
// #region

// -- Debug
// #region

// Breakpoint <none> -> <none>
// Creates a breakpoint
global function Breakpoint
{
    print "* Press any key to continue *" at (10, terminal:height - 2).
    terminal:input:getChar().
    print "                             " at (10, terminal:height - 2).
}
// #endregion


// -- Sound
// #region

// PlaySFX :: <int> -> <none>
// Plays a sound effect based chosen by param idx
global function PlaySFX
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
// #endregion


// -- Vessel Cache / State
// #region

// - Cache
// #region

// CacheState :: [<any>, <any>] -> <any>
// Caches a key/value pair in the state file
global function CacheState
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

// PeekCache :: <any> -> <bool>
// Checks state file for existence of key and returns true/false
global function PeekCache
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

// ReadCache :: <any> -> <any | bool>
// Reads the value of the passed in key. 
// Returns false if key does not exist
global function ReadCache
{
    parameter lexKey.

    if exists(stateFile)
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey(lexKey) return stateObj[lexKey].
    }
    return false.
}

// ClearCacheKey :: <any> -> <bool>
// Clears a value from the state file
// Returns bool on operation success / fail
global function ClearCacheKey
{
    parameter lexKey.

    if exists(stateFile) 
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey(lexKey)
        {
            stateObj:remove(lexKey).
            writeJson(stateObj, stateFile).
            return true.
        }
        else
        {
            return false.
        }
    }
}

// DeleteCache :: <none> -> <bool>
// Removes the entire state file
// Returns bool on success / fail
global function DeleteCache
{
    deletePath(stateFile).
    if not exists(stateFile) 
    {
        return true.
    }
    else
    {
        return false.
    }
}

// PurgeCache :: <none> -> <none>
// Resets the entire state file to an empty state
// Returns bool on success / fail
global function PurgeCache
{
    writeJson(lex(), stateFile).
    if readJson(stateFile):keys:length = 0
    {
        return true.
    }
    else
    {
        return false.
    }
}
// #endregion

// - Runmode
// #region

// InitRunmode :: <none> -> <int>
// Gets the runmode from disk if exists, else returns 0
global function InitRunmode
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
            return 0.
        }
    }
    else
    {
        writeJson(lex("runmode", 0), stateFile).
    }
    return 0.
}

// Runmode :: [<int>] -> <int>
// Combination function. 
// No param: Reads the runmode from cache or returns 0 if cache doesn't contain runmode key
// With param: Writes the value to the cache and returns it back to the function
global function Runmode
{
    parameter runmode is -1.

    if runmode < 0 
    {
        return InitRunmode().
    }
    else
    {
        return SetRunmode(runmode).
    }

} 

// SetRunmode :: <int> -> <int>
// Writes the runmode to disk, and returns the value back to the function
global function SetRunmode
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
// #endregion
// #endregion

// -- List
// #region
// Sorts a list of parts by stage
// Possible sortDir values: asc, desc
global function OrderPartsByStageNumber
{
    parameter inList,
              sortDir is "desc".

    local outList    to list().
    local startCount to choose -1 if sortDir = "asc" else stage:number.
    local endCount   to choose stage:number if sortDir = "asc" else -2.

    from { local c to startCount.} until c = endCount step { set c to stepList(c, sortDir). } do
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
// #endregion


// -- Checks
// #region
// Function for use in maneuver delegates
global function CheckMnvDelegate
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

// CheckSteering :: [<str>], [<int>]:: <bool>
// Given a generic "angle" argument or specific control axis (roll, pitch, yaw), 
// returns a bool if steeringManager values are within the optional zero-centered range
global function CheckSteering
{
    parameter axis is "angle",
              accRange to 0.025.

    if axis = "angle" 
    {
        if steeringManager:angleError >= -accRange and steeringManager:angleError <= accRange 
        {
            return true.
        }
        else
        {
            return false.
        }
    }
    else if axis = "roll"
    {
        if steeringManager:rollError >= -accRange and steeringManager:rollError <= accRange 
        {
            return true.
        }
        else
        {
            return false.
        }  
    }
    else if axis = "pitch"
    {
        if steeringManager:pitchError >= -accRange and steeringManager:pitchError <= accRange 
        {
            return true.
        }
        else
        {
            return false.
        }  
    }
    else if axis = "yaw"
    {
        if steeringManager:yawError >= -accRange and steeringManager:yawError <= accRange 
        {
            return true.
        }
        else
        {
            return false.
        }  
    }
}

// Checks if a value is above/below the range bounds given
global function CheckValRange
{
    parameter val,
              rangeLo,
              rangeHi.

    if val >= rangeLo and val <= rangeHi return true.
    else return false.
}
// #endregion


// -- Core Messages
// #region
global function CheckMsgQueue
{
    local msgList to list().
    if not core:messages:empty
    {
        wait until core:messages:length >= 2.
        local msgComplete to false.
        until msgComplete
        {
            local sender to core:messages:pop():content.
            local msgVal to core:messages:pop().
            local msgTime to msgVal:receivedAt.
            msgList:add(msgTime).
            msgList:add(sender).
            msgList:add(msgVal:content).
            set msgComplete to true.
        }
    }
    return msgList.
}

global function SendMsg
{
    parameter sendTo, 
              msgData.

    if sendTo = "root" set sendTo to ship:rootPart:tag.
    local cx to processor(sendTo):connection.

    cx:sendMessage(core:part:tag). 
    cx:sendMessage(msgData).
}
// #endregion


// -- Terminal / AG Input Checks
// #region
// Checks if a provided value is within allowed deviation of a target value
global function CheckValDeviation
{
    parameter val,
              tgtCenter,
              maxDeviation.

    if val >= tgtCenter - maxDeviation and val <= tgtCenter + maxDeviation return true.
    else return false.
}

global function CheckChar
{
    parameter varToCheck, charToCheck.

    if varToCheck = charToCheck return true.
    else return false.
}

global function CheckInputChar
{
    parameter charToCheck.
    
    if terminal:input:hasChar
    {
        if terminal:input:getChar = charToCheck
        {
            return true.
        }
        else
        {
            return false.
        }
    }
    return false.
}

global function GetInputChar
{
    if terminal:input:hasChar
    {
        return terminal:input:getChar.
    }
    return "".
}

global function WaitOnTermInput
{
    local tick to 0.

    until false
    {
        if terminal:input:haschar
        {
            return terminal:input:getChar().
        }
        OutInfo2("No Char | Tick: " + tick).
        set tick to choose 0 if tick > 999 else tick + 1.
        wait 0.01.
    }
}

global function WaitOnAllInput
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
// #endregion


// -- Part Modules
//#region
// Checks for an action and executes if found
global function DoAction
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
global function DoEvent
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
global function GetEventFromModule
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
global function ToggleUSBayDoor
{
    parameter bay,
              doors is "all".

    local aniMod to "USAnimateGeneric".
    local pEvent to "deploy primary bays".
    local sEvent to "deploy secondary bays".

    if doors = "all" or doors = "primary"
    {
        DoEvent(bay:getModule(aniMod), pEvent).
    }
    if doors = "all" or doors = "secondary"
    {
        DoEvent(bay:getModule(aniMod), sEvent).
    }
}

global function InitCapacitorDischarge
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
            DoEvent(m, "disable recharge").
            DoEvent(m, "discharge capacitor").
            until ecMon >= 0.99 or cap:resources[0]:amount <= 0.1
            {
                wait 0.01.
            }
        }
    }
}

global function SetGrappleHook
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

    DoEvent(m, event).
}
//#endregion


// -- Warp
// #region
// Creates a trigger to warp to a timestamp using AG10
global function InitWarp
{
    parameter tStamp, 
              str is "timestamp",
              buffer is 15,
              warpNow to false.

    set tStamp to tStamp - buffer.
    if time:seconds <= tStamp
    {
        if warpNow 
        {
            warpTo(tStamp).
            wait until kuniverse:timewarp:issettled.
        }
        else
        {
            when CheckInputChar(terminal:input:enter) then
            {
                warpTo(tStamp).
                wait until kuniverse:timewarp:issettled.
            }
            OutHUD("Press Enter in terminal to warp to " + str).
        }
    }
    else
    {
        OutHUD("Warp not available, too close to timestamp", 1).
    }
}

// Smooths out a warp down by either altitude or timestamp
global function WarpToAlt
{
    parameter tgtAlt.
    
    local dir to choose "down" if ship:altitude > tgtAlt else "up".

    if dir = "down"
    {
        if ship:altitude <= tgtAlt * 1.01 set warp to 0.
        else if ship:altitude <= tgtAlt * 1.15 set warp to 1.
        else if ship:altitude <= tgtAlt * 1.35 set warp to 2.
        else if ship:altitude <= tgtAlt * 2 set warp to 3.
        else if ship:altitude <= tgtAlt * 4 set warp to 4.
        else if ship:altitude <= tgtAlt * 8 set warp to 5.
        else if ship:altitude <= tgtAlt * 16 set warp to 6.
        else set warp to 7.
    }
    else if dir = "up"
    {
        if ship:altitude >= tgtAlt * 0.99 set warp to 0.
        else if ship:altitude >= tgtAlt * 0.95 set warp to 1.
        else if ship:altitude >= tgtAlt * 0.80 set warp to 2.
        else if ship:altitude >= tgtAlt * 0.70 set warp to 3.
        else if ship:altitude >= tgtAlt * 0.35 set warp to 4.
        else if ship:altitude >= tgtAlt * 0.20 set warp to 5.
        else if ship:altitude >= tgtAlt * 0.05 set warp to 6.
        else set warp to 7.
    }
}
// #endregion


// -- Local
// #region

// StepList
// Helper function for from loop in list sorting. 
local function stepList
{
    parameter c,
              sortDir.

    if sortDir = "desc" return c - 1.
    else return c + 1.
}
// #endregion

// #endregion