@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/disp").

// *~ Variables ~* //
//#region

// -- Local
// #region
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
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
).
// #endregion

// -- Global
// #region
global BodyInfo to lex(
    "altForSci", lex(
        "Kerbin", 625000,
        "Mun", 150000,
        "Minmus", 75000,
        "Moho", 100000
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

global tConstants to lex(
    "KnToKg", 0.00980665
    ,"KgToKn", 101.97162
).

global StateFile to dataDisk + "state.json".

global FuelCellResources to lex(
    "USFuelCellMedium", list("Hydrogen", "Oxygen")
).
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
        print "* Press any key to continue *" at (10, terminal:height - 2).
        terminal:input:getChar().
        print "                             " at (10, terminal:height - 2).
    }
    // #endregion

    // Flow Control
    // #region

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

    // GenerateList :: [start value<Scalar>, end value<Scalar>, step value<Scalar>] -> : List<Scalar>
    // Generates a list of numbers starting at the low range, and incrementing up to the max range
    global function GenerateList
    {
        parameter stVal,
                  endVal,
                  stepVal.

        local wrkList to list().

        from { local fVar to stVal.} until fVar > endVal step { set fVar to fVar + stepVal.} do
        {
            wrkList:add(fVar).
        }
        return wrkList.
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
            wait 0.13.
        }
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
    parameter accRange is 0.25, 
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
        wait 0.01.
        set g_termChar to terminal:input:getChar.
        terminal:input:clear.
        return g_termChar.
    }
    return "".
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

// <PromptSelect> :: [<str>] promptID (used in cache key)], [<str> prompt string], [<list> list of choices] -> <selected item>
global function PromptItemSelect
{
    parameter promptId,
              promptStr,
              choices.

    clrDisp().
    set g_line to 10.
    
    local curSel to -1.
    local defVal to 0.
    local timeout to 15.
    local tBreak to time:seconds + timeout.
    
    CacheState("PromptSelect", lex(promptId, -1)).

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

global function PromptTextEntry
{
    parameter promptStr,
              cacheInput is false,
              promptId is "TextEntry".

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
// #endregion
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
    if usBay
    {
        set priCloseEvent to "retract primary bays".
        set priOpenEvent to "deploy primary bays".
    }

    if bayMod:HasEvent(priCloseEvent) or bayMod:HasEvent(priOpenEvent)
    {
        local secCloseEvent to "retract secondary bays".
        local secOpenEvent to "deploy secondary bays".
        local eventList to list().

        if doors = "all" or doors = "primary"
        {
            if action = "toggle" 
            {
                if bayMod:HasEvent(priOpenEvent) DoEvent(bayMod, priOpenEvent).
                else if DoEvent(bayMod, priOpenEvent).
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

        if doors = "all" or doors = "secondary"
        {
            if action = "toggle" 
            {
                if bayMod:HasEvent(secOpenEvent) eventList:add(secOpenEvent).
                else if eventList:add(secCloseEvent).
            }
            else if action = "open"
            {
                if bayMod:HasEvent(secOpenEvent) eventList:add(secOpenEvent).
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

    from { local idx to 0.} until idx > maxDeployStep step { set idx to idx + 1.} do 
    {
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

    if p:hasModule("ModuleDeployableRadiator")
    {
        DeployRadiator(p, action).
    }

    if p:hasModule("ModuleDeployableReflector")
    {
        DeployReflector(p, action).
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
        if ship:altitude <= tgtAlt * 1.000625 * warpFactor set warp to 0.
        else if ship:altitude <= tgtAlt * 1.00125 * warpFactor set warp to 1.
        else if ship:altitude <= tgtAlt * 1.025 * warpFactor set warp to 2.
        else if ship:altitude <= tgtAlt * 1.75 * warpFactor set warp to 3.
        else if ship:altitude <= tgtAlt * 5 * warpFactor set warp to 4.
        else if ship:altitude <= tgtAlt * 25 * warpFactor set warp to 5.
        else set warp to 6.
        //else if ship:altitude <= tgtAlt * 100 set warp to 6.
        //else set warp to 7.
    }
    else
    {
        if ship:altitude >= tgtAlt * 0.975 * warpFactor set warp to 0.
        else if ship:altitude >= tgtAlt * 0.85 * warpFactor set warp to 1.
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


// -- Local
// #region

// #region -- Misc
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

// #region -- Part deployment helpers
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

    local m to p:getModule("ModuleDeployableRadiator").

    if action = "toggle"
    {
        if not DoEvent(m, "extend radiator") 
        {
            if not DoEvent(m, "activate radiator")
            {
                if not DoEvent(m, "retract radiator")
                {
                    DoEvent(m, "shutdown radiator").
                }
            }
        }
    }
    else if action = "deploy"
    {
        if not DoEvent(m, "extend radiator").
        {
            DoEvent(m, "activate radiator").
        }
    }
    else if action = "retract"
    {
        if not DoEvent(m, "retract radiator")
        {
            DoEvent(m, "shutdown radiator").
        }
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
        DoEvent(m, "Toggle Hinge").
    }
    else if action = "retract"
    {
        DoEvent(m, "Toggle Hinge").
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
// #endregion

// #endregion

// #endregion