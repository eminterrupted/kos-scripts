@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/disp").

// *~ Variables ~* //
//#region

// -- Local
// #region
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.

// local _logLine to 0.
// local _arcLogPath to "0:/log/" + core:part:ship:name:replace(" ","_") + "/archived.log".
//     set _arcLogPath to choose Path(_arcLogPath) if exists(Path(_arcLogPath)) else Create(_arcLogPath).
// local _locLogPath to GetLogVol():keys[0] + ":/log/local.log".
//     set _locLogPath to choose Path(_locLogPath) if exists(Path(_locLogPath)) else Create(_locLogPath).

local deployModules to list(
    "ModuleAnimateGeneric"
    ,"USAnimateGeneric"
    ,"ModuleRTAntenna"
    ,"ModuleDeployableSolarPanel"
    ,"ModuleResourceConverter"
    ,"ModuleGenerator"
    ,"ModuleDeployablePart"
    ,"ModuleRoboticServoHinge"
    ,"ModuleRoboticServoRotor"
    ,"ModuleDeployableReflector"
    ,"SnacksConverter"
    ,"ModuleSystemHeatConverter"
    ,"ModuleSystemHeatFissionEngine"
    ,"ModuleDeployableRadiator"
    ,"RetractableLadder"
    ,"ModuleRoboticServoPiston"
).
// #endregion

// -- Global
// #region
global alphaNumDict to list(
    "0","1"
    ,"2","3"
    ,"4","5"
    ,"6","7"
    ,"8","9"
    ,"a","A"
    ,"b","B"
    ,"c","C"
    ,"d","D"
    ,"e","E"
    ,"f","F"
    ,"g","G"
    ,"h","H"
    ,"i","I"
    ,"j","J"
    ,"k","K"
    ,"l","L"
    ,"m","M"
    ,"n","N"
    ,"o","O"
    ,"p","P"
    ,"q","Q"
    ,"r","R"
    ,"s","S"
    ,"t","T"
    ,"u","U"
    ,"v","V"
    ,"w","W"
    ,"x","X"
    ,"y","Y"
    ,"z","Z"
    ,".",","
    ,"'","`"
    ,"[","]"
    ,"{","}"
    ,"(",")"
    ," ","~"
    ,"-","_"
    ,"=","+"
    ,"!","@"
    ,"#","$"
    ,"%","^"
    ,"&","*"
).

global BodyInfo to lex(
    "Kerbin", lex(
        "SpaceAltThresh", 625000
        ,"AtmAltThresh", 18000
    ),
    "Mun", lex(
        "SpaceAltThresh", 150000
    ),
    "Minmus", lex(
        "SpaceAltThresh", 75000
    ),
    "Moho", lex(
        "SpaceAltThresh", 200000
    ),
    "Eve", lex(
        "SpaceAltThresh", 1000000
        ,"AtmAltThresh", 18000
    ),
    "Gilly", lex(
        "SpaceAltThresh", 15000
    ),
    "Duna", lex(
        "SpaceAltThresh", 350000
    ),
    "Ike", lex(
        "SpaceAltThresh", 125000
    ),
    "Jool", lex(
        "SpaceAltThresh", 10000000
    ),
    "Laythe", lex(
        "SpaceAltThresh", 500000
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

global situMask to lex(
    0, "000000"
    ,1, "000001"
    ,2, "000010"
    ,3, "000011"
    ,7, "000111"
    ,12,"001100"
    ,16,"010000"
    ,31,"011111"
    ,32,"100000"
    ,48,"110000"
    ,51,"110011"
    ,56,"111000"
    ,60,"111100"
    ,61,"111101"
    ,63,"111111"
    ,"def", lex(
        0,"InSpaceHigh"
        ,1,"InSpaceLow"
        ,2,"FlyingHigh"
        ,3,"FlyingLow"
        ,4,"SrfSplashed"
        ,5,"SrfLanded"
    )
).

global expReqMask to lex(
    -1,"0000"
    ,0,"1111"
    ,1,"0001"
    ,2,"0010"
    ,3,"0011"
    ,4,"0100"
    ,5,"0101"
    ,6,"0110"
    ,7,"0111"
    ,8,"1000"
    ,"def", lex(
        0,"ScientistCrew",
        1,"CrewInPart",
        2,"CrewInVessel",
        3,"VesselControl"
    )
).


global tConstants to lex(
    "KnToKg", 0.00980665
    ,"KgToKn", 101.97162
).

global StateFile to dataDisk + "state.json".

global FuelCellResources to lex(
    "USFuelCellMedium", list("Hydrogen", "Oxygen")
).

global verbose to true.
// #endregion
//#endregion


// *~ Functions ~* //
// #region

// -- Core
// #region

    // Debug
    // #region

    // Breakpoint <none> -> <none>
    // Creates a breakpoint
    global function Breakpoint
    {
        parameter _str to "Press any key to continue".

        print "-* {0} *-":format(_str) at (10, terminal:height - 2).
        terminal:input:getChar().
        print "{0,-50}":format(" ") at (10, terminal:height - 2).
    }
    // #endregion

    // Alarm / Caution / Warning
    // #region

    // Master alarm
    // By default, simply shows the alarm string via OutTee
    // Can be configured via params to block script execution and play audible alarm
    // Can also show warning and information
    global function MasterAlarm
    {
        parameter str,
                  _errLvl is 0,
                  blocking is false,
                  soundOn is false.

        set errLvl to _errLvl.
        local alarmInterval to 2.
        local errTypeStr to choose "ALARM" if errLvl = 0
            else choose "WARNING" if errLvl = 1
            else "CAUTION".
        local errStr to "[*{0}*] {1}":format(errTypeStr, str).

        // Show alarm on interval
        if g_alarmTimer > time:seconds
        {
            OutTee(errStr, 0, 0, alarmInterval).
            set g_alarmTimer to time:seconds + alarmInterval.
        }
        
        // If the alarm should block further script execution, check for dismissal.
        // Return true to indicate alarm is dismissed / non-blocking
        // Return false to indicate alarm has not been dismissed
        if blocking
        {
            if CheckInputChar(terminal:input:endcursor) 
            {
                return true.
            }
            else
            {
                return false.
            }
        }
        return true.
    }
    // #endregion

    // Log
    // #region

    // GetLogVol :: [<ship>] -> Path()
    // Returns a path of a log file after finding the best location (has most space that is not this volume if multiple available, and is not ever staged off)
    // 
    local function GetLogVol
    {
        parameter ves is ship.

        local bestVol to core:volume.
        local maxSpace to 0.
        for cpu in ves:modulesNamed("kOSProcessor")
        {
            if cpu:volume:freeSpace > maxSpace and cpu:part:decoupledIn <= g_stopStage 
            {
                set bestVol to cpu:volume.
                set maxSpace to cpu:volume:freeSpace.
                
            }
        }
        return lex(buildList("volumes"):find(bestVol), bestVol).
    }


    // Prints the input value to the mission log
    global function OutLog
    {
        parameter str is "",
                _errLvl is 0.


        set errLvl to _errLvl.
        set _logLine to mod(_logLine + 1, 10).
        
        local locLog to open(_locLogPath).

        if errLvl = 0 
        {
            set str to "[{0,0:00}][INFO] {1}{2}":format(round(missionTime, 2), str, char(10)).
        }
        else if errLvl = 1 
        {
            set str to "[{0,0:00}][WARN] {1}{2}":format(round(missionTime, 2), str, char(10)).
        }
        else if errLvl = 2 
        {
            set str to "[{0,0:00}][ERR*] * {1} *{2}":format(round(missionTime, 2), str, char(10)).
        }
        else 
        {
            set str to "{0} *** {1}{2}":format("":padLeft(missionTime:toString():length + 7), str, char(10)).
        }


        if homeConnection:isConnected
        {
            if _logLine > 0 and _locLogPath:volume:freeSpace > str:length
            {
                set errLvl to choose 0 if locLog:write(str + char(10)) else 1.
            }
            else if _logLine = 0 or _locLogPath:volume:freeSpace <= (str:length + 1)
            {
                local arcLog to open("0:/log/" + ship:name:replace(" ","_") + "/archive.log").
                set errLvl to choose 0 if arcLog:write(locLog:readAll:string + char(10)) else 1.
                locLog:clear.
                return errLvl.
            }
        }
    }

    global function OutLogTee
    {
        parameter str,
                pos is "-0",
                _errLvl is 0.

        set errLvl to _errLvl.
        if pos[1] = "1" OutHUD().
        if pos[0]:toNumber(-1) > 0 OutMsg(str, errLvl, pos).
        if not OutLog(str, errLvl)
        {

        }
    }
    // #endregion

    // Flow Control
    // #region

    // Stk :: <none> -> <int>
    // Increments a Stk pointer to a value in the Stk
    global function Stk
    {
        parameter _val,
                  _op to "+".

        if _op = "=" {
            if _val:isType("scalar") 
            {
                g_stack[_val].
                return _val.
            }
            else 
            {
                local _valIdx to g_stack:values:indexOf(_val).
                g_stack:remove(_valIdx).
                return _valIdx.
            }
        }
        else if _op = "=v"
        {
            local _valIdx to g_stack:values:indexOf(_val).
            g_stack:remove(_valIdx).
            return _valIdx.
        }
        else if _op = "+" 
        {
            set g_stack[g_stack] to _val.
            set g_stack to 
            {
                if g_stack:length > 0
                {
                    local minNum to g_stack[0].
                    for num in g_stack
                    {
                        if num < minNum
                        {
                            set minNum to num.
                        }
                    }
                    g_stack:remove(g_stack:indexOf(minNum)).
                    return minNum.
                }
                return g_stack + 1.
            }.
        }
        else if _op = "-" 
        {
            if _val:isType("scalar") 
            {
                g_stack:remove(_val).
                if _val = g_stack
                {
                    set g_stack to g_stack - 1.   
                }
                else
                {
                    g_stack:add(_val).
                }
            }
            else
            {
                local _valIdx to g_stack:values:indexOf(_val).
                g_stack:remove(_valIdx).
                if _valIdx = g_stack
                {
                    set g_stack to g_stack - 1.   
                }
                else
                {
                    g_stack:add(_valIdx).
                }
            }
        }
    }

    // Pause :: [[Time to continue]<int>] -> <none>
    // Pauses the script. Script can continue after "Enter" input.
    // If an int is provided as a param, script will continue after that many seconds have passed OR.
    global function Pause
    {
        parameter sWait is 0.

        if sWait > 0
        {
            local pauseStr to "{0, -4} PAUSED {0, 4}".
            local pauseFlair to list("***", "**", "*", "").
            local contStr to "PRESS ENTER TO CONTINUE ({0})".
            local ts to time:seconds.
            lock timeLeft to ts - time:seconds.
            clr(terminal:height - 5).
            clr(terminal:height - 3).
            until timeLeft <= 0
            {
                if CheckInputChar(Terminal:Input:Enter) break.

                local pStr to pauseStr:format(pauseFlair[Mod(timeLeft, 3)]).
                print pStr at ((terminal:width / 2) - pStr:length, terminal:height - 5).
                
                local cStr to contStr:format(timeLeft).
                print cStr at ((terminal:width / 2) - cStr:length, terminal:height - 3).
            }
            unlock timeLeft.
            clr(terminal:height - 5).
            clr(terminal:height - 3).
        }
    }
    // #endregion

    // Basic Utilities
    // #region

    // Hash :: [<val>Any value to hash] :: <string>Hash
    // Returns a hash given an object. What exactly is hashed is dependent on the object type
    // String: The string itself
    // Scalar: The value
    // List: Summed and Averaged representation of all items in the list
    global function Hash
    {
        parameter val.

        local result to "".

        local valStr to choose val if val:IsType("String") else val:toString.

        for char in valStr
        {
            local pIdx to alphaNumDict:indexOf(char).
            local newChar to alphaNumDict[round(mod(pIdx + ((alphaNumDict:length - pIdx) / 2), alphaNumDict:Length - 1))].
            set result to result + newChar.
        }

        return result.
    }

    // MakeArray :: [<int>Length, <val>StartingValue, <functionDelegate>] :: <List>Items
    global function MakeArray
    {
        parameter tLen,
                  stVal,
                  funcDel.

        local arr to list(stVal).
        local nextVal to stVal.
        from { local i to 1.} until i = tLen step { set i to i + 1.} do 
        {
            set nextVal to funcDel:call(nextVal).
            arr:add(nextVal).
        }
        return arr.
    }

    // MakeDict :: [<list>Keys, <list>Values] -> <lexicon>
    global function MakeDict
    {
        parameter _keys,
                  _vals.

        local retLex to lexicon().
        from { local i to 0.} until i = _keys:length step { set i to i + 1.} do
        {
            set retLex[_keys[i]] to _vals[i].
        }
        return retLex.
    }

    // GetUnique :: [<list>] -> <list>
    // Returns only unique values from the source list
    global function GetUnique
    {
        parameter srcList.

        local outSet to uniqueSet().
        for i in srcList
        {
            outSet:add(i).
        }
        return outSet.
    }

    // Sound
    // #region

    // PlaySFX :: <int> -> <none>
    // Plays a sound effect based chosen by param idx
    global function PlaySFX
    {
        parameter sfxId is 0.

        if sfxId = 0 set sfxId to readJson("0:/sfx/ZeldaUnlock.json").
        local v0 to getVoice(9).
        from { local idx to 0.} until idx = sfxId:length step { set idx to idx + 1.} do
        {
            v0:play(sfxId[idx]).
            wait 0.06.
        }
    }
    // #endregion

    // Situation / Experiment decoding and checking
    // #region

    // CheckCurrentSituation :: [<int>situMask] -> <bool>
    // Checks if the vessel currently satisfies the provided situ mask
    global function CheckCurrentSituation
    {
        parameter maskInt.

        local curSitu to GetCurrentSituation().
        local situStr to GetSituationFromMask(maskInt).
        
        return situStr:contains(curSitu).
    }

        // CheckCurrentSituation :: [<int>situMask] -> <bool>
    // Checks if the vessel currently satisfies the provided situ mask
    global function CheckCurrentSituationDetailed
    {
        parameter maskObj.

        local bitMask to 0.
        
        local curSitu to GetCurrentSituation().
        local situStr to GetSituationFromMask(maskObj[0]).
        local biomeStr to GetSituationFromMask(maskObj[1]).
        

        if situStr.Contains(curSitu) 
        {
            set bitMask to bitMask + 1.
            if biomeStr.Contains(curSitu) 
            {
                set bitMask to bitMask + 1.
            }
        }

        if maskObj[2] = -1
        {
            if atm:exists 
            {
                set bitMask to 0.
            }
        }

        else if maskObj[2] = 1
        {
            if not atm:exists
            {
                set bitMask to 0.
            }
        }

        return bitmask.
    }

    // GetCurrentSituationMask :: <int> -> string
    // Returns a semicolon-delimited string of situations indicated by mask
    global function GetCurrentSituation
    {
        local curSitu to "".

        if list("SUBORBITAL", "ORBITING", "ESCAPING"):contains(ship:status)
        {
            set terminal:height to 120.
            set terminal:width to 300.
            set curSitu to choose situMask:def[0] if ship:altitude >= BodyInfo[Body:Name]:SpaceAltThresh else situMask:def[1].
        }
        else if list("FLYING"):contains(ship:status)
        {
            set curSitu to choose situMask:def[2] if ship:altitude >= BodyInfo[Body:Name]:AtmAltThresh else situMask:def[3].
        }
        else 
        {
            set curSitu to choose situMask:def[4] if ship:status = "SPLASHED" else situMask:def[5].
        }
        return curSitu.
    }

    // GetSituationFromMask :: <int> -> string
    // Returns a semicolon-delimited string of situations indicated by mask
    global function GetSituationFromMask
    {
        parameter maskInt.

        local bitmask to situMask[maskInt].
        local situStr to "".
        if bitmask:length = 6 
        {
                        
            from { local bitIdx to 0.} until bitIdx = bitmask:length step { set bitIdx to bitIdx + 1.} do 
            {
                if bitmask[bitIdx] = "1" set situStr to "{0};{1}":format(situStr, situMask:Def[bitIdx]).
            }
        }
        return situStr.
    }
    // #endregion

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

// CheckCacheKey :: <any> -> <bool>
// Checks state file for existence of key and returns true/false
global function CheckCacheKey
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

// PullCache :: (cacheKey <any>) -> <any | bool>
// Checks for key in cache. If exists, return it and 
// remove it from the cache file.
global function PullCache
{
    parameter lexKey is "".

    if exists(StateFile)
    {
        local stateObj to readJson(stateFile).
        if stateObj:HasKey(lexKey) 
        {
            local keyVal to stateObj[lexKey].
            stateObj:remove(lexKey).
            writeJson(stateObj, stateFile).
            return keyVal.
        }
    }
    return false.
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

// ReadCache :: <any> -> <any | bool>
// Reads the value of the passed in key in the cache. 
// Returns 'def' if key does not exist
global function ReadCache
{
    parameter lexKey,
              def is false.

    if exists(stateFile)
    {
        local stateObj to readJson(stateFile).
        if stateObj:hasKey(lexKey) return stateObj[lexKey].
    }
    return def.
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

// SetRunmode :: <int> -> <int>
// Writes the runmode to disk, and returns the value back to the function
global function SetRunmode
{
    parameter rm is 0.

    if rm <> 0 
    {
        if exists(stateFile) 
        {
            local curState to readJson(stateFile).
            set curState["runmode"] to rm.
            writeJson(curState, stateFile).
        }
        else
        {
            writeJson(lex("runmode", rm), stateFile).
        }
    }
    else if exists(stateFile) deletePath(stateFile).

    return rm.
}
// #endregion
// #endregion

// -- List
// #region

    // Local Helpers
    // #region
    // StepList
    // Helper function for from loop in list sorting. 
    local function StepList
    {
        parameter c,
                sortDir.

        if sortDir = "desc" return c - 1.
        else return c + 1.
    }
    // #endregion

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
    parameter accRange is 0.50, 
              axis is "angle".

    if axis = "angle" 
    {
        return steeringManager:angleError >= -accRange and steeringManager:angleError <= accRange.
    }
    else if axis = "roll"
    {
        return steeringManager:rollError >= -accRange and steeringManager:rollError <= accRange.
    }
    else if axis = "pitch"
    {
        return steeringManager:pitchError >= -accRange and steeringManager:pitchError <= accRange.
    }
    else if axis = "yaw"
    {
        return steeringManager:yawError >= -accRange and steeringManager:yawError <= accRange.
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

    local cx to processor(sendTo):connection.
    
    cx:sendMessage(core:part:uid). 
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
              maxDeviation,
              maxVal to -1.

    if maxVal = -1 
    {
        if val >= tgtCenter - maxDeviation and val <= tgtCenter + maxDeviation return true.
        else return false.
    }
    else 
    {
        if val >= Mod(maxVal + tgtCenter - maxDeviation, maxVal) and val <= Mod(maxVal + tgtCenter + maxDeviation, maxVal) return true.
        else return false.
    }
}

// Checks if the character matches the variable value passed in
global function CheckChar
{
    parameter charToCheck.

    local varToCheck to GetInputChar().

    if varToCheck = charToCheck return true.
    else return false.
}

// Checks if there is an input character, and if so, if it matches the value provided.
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

// Returns the input character if present
global function GetInputChar
{
    if terminal:input:hasChar
    {
        set g_termChar to terminal:input:getChar.
        terminal:input:clear.
        return g_termChar.
    }
    else
    {
        terminal:input:clear.
        return "".
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
// #endregion

// Terminal Prompts
// #region

// PromptConfirm :: [SelectedItem<item>] -> [<bool>]
local function PromptConfirm
{
    parameter selectedItem.

    OutInfo("Confirm selection: " + selectedItem).
    OutInfo2("[Enter] Confirm | [End] Cancel").
    until false
    {
        set g_termChar to GetInputChar().
        if g_termChar = terminal:input:enter 
        {
            OutInfo().
            OutInfo2().
            return true.
        }
        else if g_termChar = Terminal:Input:EndCursor
        {
            OutInfo().
            OutInfo2().
            return false.
        }
    }
}

// PromptCursorSelect :: [Prompt string<string>], [ItemList<List>], [[Default Idx<int>]] -> [Item From List<item>]
// Allows for use of up / down keys to scroll along a list
global function PromptCursorSelect
{
    parameter promptStr, 
              choices,
              selIdx is 0.

    local _done to false.

    local wPad to terminal:width - promptStr:length - 2.
    local pStr to promptStr + ": {0, " + -wPad + "}".
    print pStr:format(choices[selIdx]) at (0, g_line).
    until _done
    {
        if Terminal:Input:HasChar
        {
            set g_termChar to GetInputChar().
            if g_termChar = terminal:input:enter
            {
                set _done to true.
            }
            else if g_termChar = terminal:input:upcursorone
            {
                set selIdx to min(selIdx + 1, choices:length - 1).
            }
            else if g_termChar = terminal:input:downcursorone
            {
                set selIdx to max(selIdx - 1, 0).
            }
            else if g_termChar = terminal:input:deleteRight
            {
                set selIdx to 0.
            }
            else if g_termChar = terminal:input:endCursor
            {
                set selIdx to choices:length - 1.
            }
            else if g_termChar = terminal:input:backspace
            {
                set _done to true.
            }
            wait 0.01.
            print pStr:format(choices[selIdx]) at (0, g_line).
        }
        wait 0.01.
    }
    return choices[selIdx].
}

// PromptFileSelect :: [fileList<list>] -> [returnVal<VolumeFile>]
// Given a list of VolumeItems, prompts the user to enter a selection by index. 
// Returns the resulting VolumeFile
global function PromptFileSelect
{
    parameter promptStr to "Choose Item by index",
              fileLex to Volume("Archive"):files.

    local selection to fileLex.
    local prevLevelLex to fileLex.

    local dirCount is -1.
    local fileCount is -1.
    local page to 0.

    from { local lvl to 0.} until dirCount = 0 step { set lvl to lvl + 1.} do 
    {
        ResetDisp().
        print promptStr at (2, g_line).

        set dirCount to 0.
        set fileCount to 0.
        // Set up an iterator for the file values in this level
        //local items to choose fileLex:lex:values if fileLex:hasSuffix("lex") else fileLex:values. 
        local items to fileLex:values.
        for i in items
        {
            if i:isFile
            {
                set fileCount to fileCount + 1.
            }
            else
            {
                set dirCount to dirCount + 1.
            }
        }

        local pageIdx to 0.
        local pageLex to lex(pageIdx, list()).
        
        local itr to fileLex:values:iterator.
        local paginate to false.

        until not itr:next
        {           
            if mod(itr:index, 10) = 0 and paginate
            {
                set pageIdx to pageIdx + 1.
                set paginate to false.
            }
            else
            {
                set paginate to true.
            }

            if pageLex:keys:contains(pageIdx)
            {
                pageLex[pageIdx]:add(itr:value).
            }
            else
            {
                set pageLex[pageIdx] to list(itr:value).
            }
        }

        local refresh to true.

        until false
        {
            if refresh 
            {
                ResetDisp().
                print promptStr at (2, g_line).
                DispFileList(pageLex[page]).
                set refresh to false.
            }

            local numCheck to -1.
            set g_termChar to GetInputChar().

            if g_termChar:IsType("String")
            {
                set numCheck to g_termChar:ToNumber(-1).
                print "Input: " + numCheck + " (" + numCheck:typeName + ")" at (2, 40).
            }
            else 
            {
                print "Input: " + g_termChar + " (" + g_termChar:typeName + ")" at (2, 40).
            }
            if numCheck >= 0
            {
                if 0 <= numCheck and numCheck < pageLex[page]:length
                {
                    set selection to pageLex[page][numCheck].
                    if PromptConfirm(selection)
                    {
                        if selection:IsFile 
                        {
                            return selection.
                        }
                        else 
                        {
                            set fileLex to selection:lex.
                            break.
                        }
                    }
                }
                else
                {
                    OutInfo2("ERROR: Selection out of range, please try again").
                    wait 1.
                    OutInfo2().
                }
            }
            else if CheckChar(terminal:input:endCursor)
            {
                print "Selected item: <..>        " at (2, cr()).
                set fileLex to prevLevelLex.
                // break.
                return fileLex.
            }
            else if CheckChar(terminal:input:rightCursorOne)
            {
                print "Selected item: <next page>      " at (2, cr()).
                set page to min(page + 1, pageLex:keys:length - 1).
                set refresh to true.
            }
            else if CheckChar(terminal:input:leftCursorOne)
            {
                print "Selected item: <prev page>      " at (2, cr()).
                set page to max(0, page - 1).
                set refresh to true.
            }
            else if not g_termChar:isType("String")
            {
                OutInfo2("ERROR: Selection not valid, please try again").
                wait 1.
                OutInfo2().
            }
            wait 0.1.
        }
    }
}

// PromptInput 
global function PromptInput
{
    parameter promptStr,
              cacheInput is false,
              promptId is "TextEntry",
              inputType is "",
              limit is false.

    if limit:isType("Boolean")
    {
        if not limit:isType(inputType)
        {
            local MET to round(missionTime, 2).
            OutLogTee("[{0,0:00}][ERR] Provided limit does not equal inputType!":format(MET, "011")).
            OutLogTee("{0} (lib/util/PromptInput) limitType: {1} reqType: {2}":format("":padLeft(MET:length + 7, limit:typename, inputType), "011")).
            return 1 / 0.
        }
    }


    clrDisp().
    set g_line to 10.

    local userStr to "".

    print promptStr + ": " at (0, g_line).
    until false
    {
        set g_termChar to GetInputChar().
        if g_termChar = Terminal:Input:Enter
        {
            print "VALUE ENTERED: [" + userStr + "]                 " at (0, g_line).
            wait 1.
            clrDisp().
            if cacheInput
            {
                CacheState(promptId, promptStr).
            }
            return userStr.
        }
        else if g_termChar = terminal:input:endcursor
        {
            // print "CANCELLING                            " at (0, g_line).
            // wait 1.
            clrDisp().
            break.
        }
        else if g_termChar = terminal:input:backspace
        {
            if userStr:length > 0
            {
                set userStr to userStr:remove(userStr:length - 1, 1).
            }
        }
        else
        {
            set userStr to userStr + g_termChar.
        }
        print promptStr + ": " + userStr + " " at (0, g_line).
    }
    return "".
}

// PromptItemMultiSelect :: [<list|lex> Items to select, [<scalar> itemLimit]] -> <Lexicon> Selections
global function PromptItemMultiSelect 
{
    parameter _items,
              _promptStr, 
              _iterFunc,
              _itemLimit is -1,
              _cacheState is false,
              _cacheKey is "".

    local _itemSelections to lexicon().
    if _items:isType("list")
    {
        if _itemLimit < 1 set _itemLimit to _items:length.
        from { local i to 0.} until i = _itemLimit step { set i to i + 1. } do
        {
            local _item to PromptItemSelect(_items, _promptStr).
            cr().
            local confirmStr to "* Press ENTER to confirm selection / DELETE to cancel *".
            print confirmStr at (max(0, (terminal:width - confirmStr:length) / 2), g_line).
            until false 
            {
                set g_termChar to GetInputChar().
                if g_termChar = terminal:input:enter
                {
                    _iterFunc:call().
                }
                else if g_termChar = terminal:input:deleteCursor
                {
                   set errLvl to _itemSelections:remove(_itemSelections:keys[_itemSelections:values:indexOf(_item)]).
                   if errLvl = 1 OutLog("Failed to move {0} from _itemSelections to _items":format(_item)).
                   else 
                   {
                    OutLog("Successfully moved {0} from _itemSelections to _items":format(_item)).
                    Stk(_item, "-").

                   _items:add(_item).
                   }
                }
            }
        }
    }
    else if _items:isType("Lexicon")
    {

    }
    return _itemSelections.
}
// <PromptSelect> :: [<list> list of choices], [<str> prompt string], [<bool> cache option on], [<string> cacheId] -> <selected item>
global function PromptItemSelect
{
    parameter choices,
              promptStr,
              cacheItem is false,
              promptId is "prmpt".

    clrDisp().
    set g_line to 10.
    
    local curSel to -1.
    local defVal to 0.
    local timeout to 15.
    local tBreak to time:seconds + timeout.
    
    CacheState(promptId, lex(promptId, -1)).

    if choices:length > 0 
    {

        print "*** " + promptStr:toUpper + " ***" at (0, g_line).
        print "------------------------" at (0, cr()).
        local t_line to g_line.
        until time:seconds >= tBreak
        {
            set curSel to ReadCache("PromptSelect")[promptId].
            set g_line to t_line - 1.
            from { local i to 0.} until i >= choices:length step { set i to i + 1.} do 
            {
                set g_prn to "[{0}]{1} {2}".
                local sel to "".

                if curSel = i 
                {
                    set sel to " (***)".
                }
                else if curSel < 0 and i = defVal
                {
                    set sel to "(DEF)".
                }
                print g_prn:format(i, sel, choices[i]) at (0, cr()).
                set g_prn to "".
            }

            if terminal:input:haschar
            {
                set g_termChar to GetInputChar().
                from { local i to 0.} until i > choices:length step { set i to i + 1.} do 
                {
                    if g_termChar = i 
                    {
                        CacheState("PromptSelect", lex(promptId, i)).
                    }
                }
                terminal:input:clear.
                wait 0.01.
                local selCached to ReadCache("PromptSelect")[promptId].
                if selCached > -1 return choices[selCached].
            }
            cr().   
            print "TIME REMAINING TO SELECT: " + round(tBreak - time:seconds, 2) + "s        " at (0, g_line + 2).
        }
        clr(g_line).
        clr(g_line + 2).
        return choices[defVal].
    }
    else return "".
}

// <PromptPartSelect> :: [<str>] promptID (used in cache key)], [<str> prompt string], [<list> list of choices], [<bool> Whether to enable part highlighting] -> <selected item>
global function PromptPartSelect
{
    parameter promptId,
              promptStr,
              partList,
              hlEnable to false.

    clrDisp().
    set g_line to 10.

    local curSel to -1.
    local defVal to 0.
    local hl to "".
    
    CacheState("PromptSelect", lex(promptId, curSel)).
    if partList:length > 1
    {
        local function ConfirmChoice
        {
            cr().
            print "CONFIRM CHOICE! ** Press [Enter] Yes | [End] No ** " at (0, g_line).
            local timeOut to time:seconds + 5.
            until false
            {
                set g_termChar to GetInputChar().
                if g_termChar = terminal:input:enter 
                {
                    return true.
                }
                else if g_termChar = Terminal:Input:EndCursor or time:seconds > timeOut
                {
                    return false.
                }
            }
        }

        local function PartHL
        {
            parameter p.

            local h to highlight(p, rgb(1, 0.15, 0.25)).
            set h:enabled to false.
            wait 0.01.
            set h:enabled to true.
            set hlUID to p:UID.
            return h.
        }

        local choiceMade to false.
        local tBreak to time:seconds + 15.
        local hlUID to 0.

        print "*** " + promptStr:toUpper + " ***" at (0, g_line).
        print "------------------------" at (0, cr()).
        local t_line to g_line.

        until time:seconds >= tBreak
        {
            set curSel to ReadCache("PromptSelect")[promptId].
            set g_line to t_line.
            from { local i to 0.} until i >= partList:length step { set i to i + 1.} do 
            {
                local curPart to partList[i].
                set g_prn to "[" + i + "] ".
                if curSel = i 
                {
                    set g_prn to g_prn + "*** ".
                    if hlEnable 
                    {
                        set hl to PartHL(curPart).
                    }
                }
                else if curSel < 0 and i = defVal
                {
                    set g_prn to g_prn + "(DEF) ".
                    if hlEnable
                    {
                        if hlUID <> curPart:UID
                        {
                            set hl to PartHL(curPart).
                        }
                    }
                }
                else
                {
                    set g_prn to g_prn.
                }
                print g_prn + curPart:name + " | " + curPart:UID + "     " at (0, cr()).
            }

            if terminal:input:haschar
            {
                set g_termChar to GetInputChar().
                from { local i to 0.} until i > partList:length step { set i to i + 1.} do 
                {
                    if g_termChar = i 
                    {
                        CacheState("PromptSelect", lex(promptId, i)).
                        set choiceMade to true.
                    }
                }
                terminal:input:clear.
                wait 0.01.
                local selCached to ReadCache("PromptSelect")[promptId].
                if selCached > -1 and choiceMade
                {
                    if ConfirmChoice()
                    {
                        return partList[selCached].
                    }
                    else
                    {
                        set choiceMade to false.
                    }
                }
            }
            cr().   
            print "TIME REMAINING TO SELECT: " + round(tBreak - time:seconds, 2) + "s        " at (0, cr()).
        }
        set hl:enabled to false.
        
        clrDisp().
        return partList[defVal].
    }
    else if partList:length > 0
    {
        return partList[0].
    }
    else
    {
        return false.
    }
}

global function PromptScalarEntry
{
    parameter _range is -1.


}

// #endregion
// #endregion

// -- Part Modules
// #region

// #region -- Part deployment helpers
// Fresh air makers
local function DeployAirMaker
{
    parameter p,
              action is "toggle".

    local m to p:getModule("SnacksConverter").

    if  action = "toggle"
    {
        DoAction(m, "toggle converter", true).
    }
    else if action = "deploy"
    {
        DoEvent(m, "start air maker").
    }
    else if action = "retract"
    {
        DoEvent(m, "stop air maker").
    }
}

// Crystallisation Facilities
local function DeployCrystalization
{
    parameter p, 
              action is "deploy".

    local m to p:getModule("ModuleSystemHeatConverter").
    
    if action = "deploy"
    {
        DoAction(m, "Start Crystallisation [Cr]", true).
    }
    else if action = "retract"
    {
        DoAction(m, "Stop Crystallisation [Cr]", true).
    }
    else if action = "toggle"
    {
        DoAction(m, "toggle converter (cyrstal)", true).
    }
}

// Fuel cells
local function DeployFuelCell
{
    parameter p,
              action.

    local m to p:getModule("ModuleResourceConverter").

    if action = "toggle"
    {
        if not DoEvent(m, "start fuel cell") DoEvent(m, "stop fuel cell").
    }
    else if action = "deploy"
    {
        DoEvent(m, "start fuel cell").
    }
    else if action = "retract"
    {
        DoEvent(m, "stop fuel cell").
    }
}

// Radiators
local function DeployRadiator
{
    parameter p,
              action.

    local m to "". 
    local eDeploy to "".
    local eRetract to "".

    if p:hasModule("ModuleSystemHeatRadiator")
    {
        set m to p:getModule("ModuleSystemHeatRadiator").
        set eDeploy to "activate radiator".
        set eRetract to "shutdown radiator".
    } 
    else if p:hasModule("ModuleDeployableRadiator")
    {
        set m to p:getModule("ModuleDeployableRadiator").
        set eDeploy to "extend radiator".
        set eRetract to "retract radiator".
    }

    if action = "toggle"
    {
        if not DoEvent(m, eDeploy) 
        {
            DoEvent(m, eRetract).
        }
    }
    else if action = "deploy"
    {
        DoEvent(m, eDeploy).
    }
    else if action = "retract"
    {
        DoEvent(m, eRetract).
    }
}


// Reactors

local function DeployReactor
{
    parameter p,
              action.

    local m to p:getModule("ModuleSystemHeatFissionEngine").
    local eDeploy to "enable reactor".
    local eRetract to "disable reactor".
    
    if action = "toggle"
    {
        if not DoEvent(m, eDeploy) 
        {
            DoEvent(m, eRetract).
        }
    }
    else if action = "deploy"
    {
        if m:getField("generation") = "Offline"
        {
            DoEvent(m, eDeploy).
        } 
    }
    else if action = "retract"
    {
        if m:getField("generation") = "Online"
        {
            DoEvent(m, eRetract).
        }
    }
}

global function ManageReactor
{
    parameter p,
              action is "info",
              data0 is "",
              data1 is "".

    local safeStartup to choose true if data0:length = 0 else data0.

    local rx to p:getModule("ModuleSystemHeatFissionEngine").
    local sh to p:getModule("ModuleSystemHeat").

    local lock rxStatus to rx:getField("generation").
    local lock rxWasteHeat to rx:getField("waste heat").
    local lock rxCoreTempStr to rx:getField("core temperature").
    local lock rxCoreTempSet to rxCoreTempStr:replace(" K",""):split("/").
    local lock rxCoreTemp to rxCoreTempSet[0]:ToNumber().
    local rxTempSpec to rxCoreTempSet[1]:ToNumber().
    local lock rxCoreHealth to rx:getField("core health"):replace(" %",""):ToNumber().
    local lock rxCoreLife to rx:getField("core life"):ToNumber(999999999).
    local lock rxTjMax to rx:getField("auto-shutdown temp").

    local shId to sh:getField("loop id").
    local lock shFlux to sh:getField("system flux").
    local lock shTemp to sh:getField("loop temperature").

    if action = "info"
    {
        return lex(
            "status", rxStatus,
            "wasteHeat", rxWasteHeat,
            "tempSpec", rxTempSpec,
            "tjMax", rxTjMax,
            "coreTemp", rxCoreTemp,
            "coreHealth", rxCoreHealth,
            "coreLife", rxCoreLife,
            "loopTemp", shTemp,
            "loopFlux", shFlux,
            "loopId", shId
        ).
    }
    else if action = "deploy"
    {
        OutMsg("[{0}] Initiating Reactor Startup Sequence":format(TimeSpan(missionTime):Full)).
        
        local safeToDeploy to true.

        if data0 <> "" set safeStartup to data0.
        
        if rxCoreHealth <= 25
        {
            OutTee("[WARN]: Reactor health at {0}. Confirm startup?":format(rxCoreHealth, 0, 1)).
            Breakpoint().
        }
        else if safeStartup
        {
            OutInfo("SafeStart check: Cooling").
            for rad in ship:modulesNamed("ModuleSystemHeatRadiator") DeployRadiator(rad:part, "deploy").
            OutInfo("SafeStart check: Temperature").
            if rxCoreTemp >= rxTempSpec
            {
                set safeToDeploy to false.
                OutTee("[WARN]: Thermal Throttling! {0} (tjMax: {1}). Aborting startup!":format(round(rxCoreTemp, 2), rxTjMax), 0, 1).
            }
            else
            {
                OutInfo2("Pass!").
                
            }
            OutInfo("SafeStart check: Health").
            OutInfo2().
            if rxCoreHealth <= 5
            {
                set safeToDeploy to false.
                OutTee("[WARN]: Reactor health at {0}. Aborting startup!":format(rxCoreHealth, 0, 1)).
            }
            else
            {
                OutInf2("Pass!").
            }
            OutInfo().
            OutInfo2().
        }
        
        if safeToDeploy DeployReactor(p, action).

        return lex(
            "status", rxStatus,
            "wasteHeat", rxWasteHeat,
            "tempSpec", rxTempSpec,
            "tjMax", rxTjMax,
            "coreTemp", rxCoreTemp,
            "coreHealth", rxCoreHealth,
            "coreLife", rxCoreLife,
            "loopTemp", shTemp,
            "loopFlux", shFlux,
            "loopId", shId
        ).
    }
    else if action = "retract"
    {
        DeployReactor(p, action).

        return lex(
            "status", rxStatus,
            "wasteHeat", rxWasteHeat,
            "tempSpec", rxTempSpec,
            "tjMax", rxTjMax,
            "coreTemp", rxCoreTemp,
            "coreHealth", rxCoreHealth,
            "coreLife", rxCoreLife,
            "loopTemp", shTemp,
            "loopFlux", shFlux,
            "loopId", shId
        ).
    }
}


// Deploy Ladders
local function DeployLadder
{
    parameter p,
              action.

    local m to p:getModule("RetractableLadder").

    if action = "toggle"
    {
        DoAction(m, "toggle ladder", true).
    }
    else if action = "deploy"
    {
        DoEvent(m, "extend ladder").
    }
    else if action = "retract"
    {
        DoEvent(m, "retract ladder").
    }
}

// Antenna Reflectors
local function DeployReflector
{
    parameter p,
              action.

    local m to p:getModule("ModuleDeployableReflector").

    if action = "toggle"
    {
        if not DoEvent(m, "extend reflector") DoEvent(m, "retract reflector").
    }
    else if action = "deploy"
    {
        DoEvent(m, "extend reflector").
    }
    else if action = "retract"
    {
        DoEvent(m, "retract reflector").
    }
}

// Robotics - Hinges
local function DeployRoboHinge
{
    parameter p,
              action.

    local lockFlag to false.
    local m to p:getModule("ModuleRoboticServoHinge").
    if m:getField("locked") 
    {
        set lockFlag to true.
        m:setField("locked", false). 
    }
    wait 0.05.
    
    if action = "toggle"
    {
        DoAction(m, "Toggle Hinge").
    }
    else if action = "deploy"
    {
        DoAction(m, "Toggle Hinge").
    }
    else if action = "retract"
    {
        DoAction(m, "Toggle Hinge").
    }

    if lockFlag 
    {
        m:setField("locked", true).
    }
}

// Robotics - Rotors
local function DeployRoboRotor
{
    parameter p,
              action.

    local m to p:getModule("ModuleRoboticServoRotor").

    if m:getField("locked") 
    {
        m:setField("locked", false). 
    }
    wait 0.05.

    if action = "toggle"
    {
        if not m:getField("motor") 
        {
            m:setField("motor", true).
            m:setField("torque limit(%)", 25).
        }
        else
        {
            m:setField("motor", false).
            m:setField("torque limit(%)", 0).
        }
    }
    else if action = "deploy"
    {
        m:setField("motor", true).
        m:setField("torque limit(%)", 25).
    }
    else if action = "retract"
    {
        m:setField("motor", false).
        m:setField("torque limit(%)", 0).
    }

    if not m:getField("motor")
    {
        m:setField("locked", true).
    }
}

// RemoteTech Antennas
local function DeployRTAntenna
{
    parameter p,
              action.

    local m to p:getModule("ModuleRTAntenna").

    if action = "toggle"
    {
        if not DoAction(m, "activate", true) DoAction(m, "deactivate", true).
    }
    else if action = "deploy"
    {
        DoEvent(m, "activate").
    }
    else if action = "retract"
    {
        DoEvent(m, "deactivate").
    }
}

// RTGs
local function DeployRTG
{
    parameter p,
              action.

    local m to p:getModule("ModuleGenerator").

    if action = "toggle"
    {
        if not DoEvent(m, "activate generator") DoEvent(m, "shutdown generator").
    }
    else if action = "deploy"
    {
        DoEvent(m, "activate generator").
    }
    else if action = "retract"
    {
        DoEvent(m, "shutdown generator").
    }
}

// Science / miscellaneous
local function DeploySciMisc
{
    parameter p,
              action.

    local m to p:getModule("ModuleDeployablePart").

    if action = "toggle"
    {
        if not DoEvent(m, "extend") DoEvent(m, "retract").
    }
    else if action = "deploy"
    {
        DoEvent(m, "deploy").
    }
    else if action = "retract"
    {
        DoEvent(m, "retract").
    }
}

// Solar Panels
local function DeploySolarPanel
{
    parameter p, 
              action.
    
    local m to p:getModule("ModuleDeployableSolarPanel").
    if action = "toggle"
    {
        if not DoAction(m, "extend solar panel", true) DoAction(m, "retract solar panel", true).
    }
    else if action = "deploy"
    {
        DoEvent(m, "extend solar panel").
    }
    else if action = "retract"
    {
        DoEvent(m, "retract solar panel").
    }
}

// TST Space Telescope
local function DeployTSTScope
{
    parameter p,
              action.

    local m to p:getModule("TSTSpaceTelescope").
    if action = "toggle"
    {
        if not DoEvent(m, "open camera", true) DoAction(m, "opencamera", true).
        wait 0.01.
    }
    else if action = "deploy"
    {
        DoEvent(m, "open camera").
        wait 0.01.
    }
    else if action = "retract"
    {
        DoEvent(m, "close camera").
        wait 0.01.
    }
}
// #endregion

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

    for _e in m:allEvents
    {
        if _e:contains(event)
        {
            return _e:replace("(callable) ", ""):replace(", is KSPEvent", "").
        }
    }

    if searchActions
    {
        for _a in m:allActions
        {
            if _a:contains(event)
            {
                return _a:replace("(callable) ", ""):replace(", is KSPAction", "").
            }
        }
    }
    return "".
}

// GetFuelCellTimeRemaining :: <part> | <scalar>
// Returns the amount of time that a fuel cell has remaining based on 
// resources it uses. 
// If no resources are currently being used (ex: Fuel Cell is off), returns -1.
global function GetFuelCellTimeRemaining
{
    parameter fc.

    local startTime to time:seconds.
    local fcTimeRemaining to startTime.

    print("Checking Fuel Cell Consumption") at (2, 10).
    if fc:getModule("ModuleResourceConverter"):hasEvent("stop fuel cell")
    {
        local fcResources to list().
        local resLex to lex().
        // set startTime to time:seconds.
        // set fcTimeRemaining to startTime.

        local fcResources to (FuelCellResources[fc:name]).

        for res in Ship:Resources
        {
            if fcResources:contains(res:name)
            {
                set resLex[res:name] to res:amount.
            }
        }

        for res in resLex:keys
        {
            for shipRes in Ship:Resources
            {
                if shipRes:Name = res
                {
                    print "Measuring " + res + " consumption          " at (2, 11).
                    local resEndTime to time:seconds + 10.
                    local resTimeRemaining to 0.
                    local resUsed to 0.
                    local startAmt to shipRes:amount.
                    until time:seconds >= resEndTime
                    {
                        print "Time remaining: " + round(resEndTime - time:seconds, 2) + "  " at (2, 12).
                    }
                    set resUsed to (startAmt - shipRes:amount) * 0.1.
                    print shipRes:Name + " usage/sec : " + round(resUsed, 2).
                    if resUsed > 0 
                    {
                        set resTimeRemaining to shipRes:amount / resUsed.
                        if fcTimeRemaining > resTimeRemaining 
                        {
                            set fcTimeRemaining to resTimeRemaining.
                        }
                    }
                }
            }
        }
    }

    if fcTimeRemaining = startTime {
        return -1.
    }
    else
    {
        return fcTimeRemaining.
    }
}

// ToggleBayDoor :: <part>, <string>, <string> | <none>
// Deploys Stock and Universal Storage bay doors
global function ToggleBayDoor
{
    parameter bay,
              doors is "all",
              action is "toggle".

    local usBay to bay:HasModule("USAnimateGeneric").
    local bayMod to choose bay:GetModule("USAnimateGeneric") if usBay else bay:GetModule("ModuleAnimateGeneric").
    local priCloseEvent to "close".
    local priOpenEvent to "open".
    local hasSecondary to false.
    local secCloseEvent to "retract secondary bays".
    local secOpenEvent to "deploy secondary bays".

    if usBay
    {
        set priCloseEvent to "retract primary bays".
        set priOpenEvent to "deploy primary bays".
        if (bayMod:hasEvent(secOpenEvent) or bayMod:hasEvent(secCloseEvent)) set hasSecondary to true.
    }

    if bayMod:HasEvent(priCloseEvent) or bayMod:HasEvent(priOpenEvent)
    {
        if doors = "all" or doors = "primary"
        {
            if action = "toggle" 
            {
                if not DoEvent(bayMod, priOpenEvent) DoEvent(bayMod, priCloseEvent).
            }
            else if action = "open"
            {
                DoEvent(bayMod, priOpenEvent).
            }
            else if action = "close"
            {
                DoEvent(bayMod, priCloseEvent).
            }
        }

        if (doors = "all" or doors = "secondary") and hasSecondary
        {
            if action = "toggle" 
            {
                if not DoEvent(bayMod, secOpenEvent)
                DoEvent(bayMod, secCloseEvent).
            }
            else if action = "open"
            {
                DoEvent(bayMod, secOpenEvent).
            }
            else if action = "close"
            {
                DoEvent(bayMod, secCloseEvent). 
            }
        }
        wait 0.07.
        until bayMod:GetField("status") = "Locked"
        {
            wait 0.01.
        }

        if bay:Tag:MatchesPattern("bay\.") 
        {
            local idx to bay:Tag:Split(".")[1].
            ToggleLights(Ship:PartsTaggedPattern("bayLight." + idx)).
        }
    }
}

// ToggleLights :: List<parts>, <str> | <none>
// Toggles / Activates / Deactivates a provided set of lights
global function ToggleLights
{
    parameter lightList, 
              action is "Toggle".

    if lightList:length > 0
    {
        for p in lightList 
        {
            if action = "Toggle" 
            {
                DoAction(p:GetModule("ModuleLight"), "toggle light").
            }
            else if action = "Activate"
            {
                DoEvent(p:GetModule("ModuleLight"), "lights on").
            }
            else if action = "Deactivate"
            {
                DoEvent(p:GetModule("ModuleLight"), "lights off").
            }
        }
    }
}

// InitCapacitorDischarge
// Discharges all capacitors on vessel
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

// SetGrappleHook :: <module>, <string> | <none>
// Performs an action using the provided grappling hook module
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

    return DoEvent(m, event).
}

// CheckPartSet :: setTag<string> | <bool>
// Checks if parts tagged with the provided setTag are present on the vessel
// Parts specified by their deployment tag type (i.e., "launch", "payload")
// Example deployment tag formats: "deploy.launch.0" || "launchDeploy.0"
global function CheckPartSet
{
    parameter setTag is "".

    if setTag = "" 
    {
        return false.
    }
    else
    {
        local regEx to setTag + ".*\.{1}\d+".
        if ship:partsTaggedPattern(regEx):length > 0 return true.
    }
}

// DeployParts :: partList<list>, action<string> | <none>
// Performs a deployment action on a set of parts
// Parts are provided as a list
global function DeployPartList
{
    parameter partsToDeploy is list().

    if partsToDeploy:length = 0
    {
        OutMsg("DeployPartList: No parts provided!").
        
    }
}

// DeployPartSet :: setTag<string>, action<string> | <none>
// Performs a deployment action on a set of parts
// Parts specified by their deployment tag type (i.e., "launch", "payload")
// Example deployment tag formats: "deploy.launch.0" || "launchDeploy.0"
global function DeployPartSet
{
    parameter setTag is "", action is "deploy".
    
    local maxDeployStep to 0.
    local regEx to setTag + ".*\.{1}\d+".
    if setTag <> "" 
    {
        for p in Ship:PartsTaggedPattern(regEx)
        {
            // if p:tag:split(".")[1]:toNumber(0) > maxDeployStep set maxDeployStep to p:tag:split(".")[1].
            local pTag to p:Tag:Split(".").
            set maxDeployStep to max(pTag[pTag:Length - 1]:ToNumber(0), maxDeployStep).
        }
    }

    local function DeployModule
    {
        parameter idx.
        
        OutInfo("Step: " + idx:ToString).
        local regEx2 to regEx:Remove(regEx:length - 3, 3) + idx:ToString.
        local idxStepList to choose Ship:PartsTagged("") if setTag = "" else Ship:PartsTaggedPattern(regEx2).
        for p in idxStepList
        {
            for m in p:AllModules
            {
                if deployModules:Contains(m)
                {
                    DeployPart(p, action).
                    wait 0.05.
                }
            }
        }
        wait 1.
    }

    if action = "deploy"
    {
        from { local idx to 0.} until idx > maxDeployStep step { set idx to idx + 1.} do 
        {
            DeployModule(idx).
        }
    }
    else if action = "retract"
    {
        from { local idx to maxDeployStep.} until idx < 0 step { set idx to idx - 1.} do 
        {
            DeployModule(idx).
        }
    }
}

// DeployPart :: <part>, action<string> -> <none>
// Given a part, performs the specified action on it
global function DeployPart
{
    parameter p, 
              action is "deploy".

    if p:hasModule("ModuleAnimateGeneric") or p:hasModule("USAnimateGeneric") // Generic and bays
    {
        if p:name:contains("Shroud") or p:name:contains("Bay") or p:tag:contains("bay") // Bays
        {
            if action = "deploy" ToggleBayDoor(p, "all", "open").
            else ToggleBayDoor(p, "all", "close").
        }
        else if p:name <> "USComboLifeSupportWedge"    // Everything else that is not a USCombo Life Support Wedge
        {
            local m to p:getModule("ModuleAnimateGeneric").
            DoEvent(m, "deploy").
        }
    }
    
    if p:hasModule("ModuleRTAntenna")   // RT Antennas
    {
        DeployRTAntenna(p, action).
    }

    if p:hasModule("ModuleDeployableSolarPanel")    // Solar panels
    {
        DeploySolarPanel(p, action).
    }

    if p:hasModule("ModuleResourceConverter") // Fuel Cells
    {
        DeployFuelCell(p, action).
    }

    if p:hasModule("ModuleGenerator") // RTGs
    {
        DeployRTG(p, action).
    }

    if p:hasModule("ModuleDeployablePart")  // Science parts / misc
    {
        DeploySciMisc(p, action).
    }

    if p:hasModule("ModuleRoboticServoHinge")
    {
        DeployRoboHinge(p, action).
    }

    if p:hasModule("ModuleRoboticServoRotor")
    {
        DeployRoboRotor(p, action).
    }

    if p:hasModule("ModuleDeployableRadiator") or p:hasModule("ModuleSystemHeatRadiator")
    {
        DeployRadiator(p, action).
    }

    if p:hasModule("ModuleDeployableReflector")
    {
        DeployReflector(p, action).
    }

    if p:hasModule("SnacksConverter")
    {
        if p:getModule("SnacksConverter"):hasField("air maker") DeployAirMaker(p, action).
    }
    
    if p:hasModule("TSTSpaceTelescope")
    {
        DeployTSTScope(p, action).
    }

    if p:hasModule("ModuleSystemHeatConverter")
    {
        if p:name:contains("crystals")
        {
            DeployCrystalization(p, action).
        }
    }

    if p:hasModule("ModuleSystemHeatFissionEngine")
    {
        DeployReactor(p, action).
    }

    if p:hasModule("RetractableLadder")
    {
        DeployLadder(p, action).
    }
}
//#endregion


// -- Warp
// #region
// CheckWarpKey :: <none> -> <bool>
// Checks if the designated warp key (Enter) is pressed.
global function CheckWarpKey
{
    if Terminal:Input:HasChar 
    {
        until not Terminal:Input:HasChar
        {
            set g_termChar to Terminal:Input:GetChar.
            if g_termChar = Terminal:Input:Enter
            {
                return true.
            }
        }
        return false.
    }
    return false.
}

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
            when g_termChar = terminal:input:enter then
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

// Smooths out a warp down by altitude
global function WarpToAlt
{
    parameter tgtAlt.
    
    local warpFactor to 1.

    if tgtAlt > 1000000 set warpFactor to 1.
    else if tgtAlt > 500000 set warpFactor to 1.01.
    else if tgtAlt > 100000 set warpFactor to 1.03.
    else if tgtAlt > 10000 set warpFactor to 1.05.
    else set warpFactor to 1.075.

    if ship:altitude > tgtAlt
    {
        if ship:altitude <= tgtAlt * 1.00003125 * warpFactor set warp to 0.
        else if ship:altitude <= tgtAlt * 1.00125 * warpFactor set warp to 1.
        else if ship:altitude <= tgtAlt * 1.025 * warpFactor set warp to 2.
        else if ship:altitude <= tgtAlt * 1.75 * warpFactor set warp to 3.
        else if ship:altitude <= tgtAlt * 5 * warpFactor set warp to 4.
        else if ship:altitude <= tgtAlt * 25 * warpFactor set warp to 5.
        else if ship:altitude <= tgtAlt * 250 set warp to 6.
        else set warp to 7.
        //else set warp to 6.
    }
    else
    {
        if ship:altitude >= tgtAlt * 0.999996875 * warpFactor set warp to 0.
        else if ship:altitude >= tgtAlt * 0.99875 * warpFactor set warp to 1.
        else if ship:altitude >= tgtAlt * 0.75 * warpFactor set warp to 2.
        else if ship:altitude >= tgtAlt * 0.625 * warpFactor set warp to 3.
        else if ship:altitude >= tgtAlt * 0.500 * warpFactor set warp to 4.
        else if ship:altitude >= tgtAlt * 0.250 * warpFactor set warp to 5.
        else set warp to 6.
        //else if ship:altitude >= tgtAlt * 0.125 set warp to 6.
        //else set warp to 7.
    }
}
// #endregion

// -- Vector Math
// #region
// Signs the angle between two vectors relative to the velocity of the vessel
global function SignedVAng
{
    parameter ves,
              vec1, 
              vec2.

    local vecAng to VAng(vec1, vec2).
    local sign to VDot(VCrs(vec2, vec1), vCrs(ves:velocity:orbit, vec1)).
    if sign > 0
    {
        set vecAng to 360 - vecAng.
    }
    return vecAng.
}
//#endregion


// -- Misc Local
// #region

// #endregion