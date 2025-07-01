@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #include "0:/env/types/base_types.ks"
// #include "0:/env/types/string_types.ks"
// #include "0:/env/types/term_types.ks"

RunOncePath("0:/env/types/_init.ks").
RunOncePath("0:/env/types/term_types.ks").

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region
    
    local g_Context         to 0.
    local g_MissionPlan     to 0.
    local g_MissionPlanId   to 0.
    local g_Program         to 0.
    local g_Runmode         to 0.
    local g_State           to 0.
    local g_StateCache      to lex().
    local g_StateCachePath  to "1:/_state.json".

    local g_StageLimit      to 0.

    // #endregion

    // *- Delegates
    // #region

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Bit operations
    // #region

    // HexToCharCode :: _hexStr<string>, _charPath<string> -> outStr<string>
    // Converts a 1,2, or 4-char hex string to the appropriate bit mask
    global function HexToBitMask
    {
        parameter _hexStr,
                  _bitDepth is 0. // 0: 4 bits, 1: 8 bits, 2: 12 bits, 3: 16 bits

        local outBytes to list().
        for _ch in _hexStr
        {
            outBytes:Add(BitMaskRef:Hex[_ch]).
        }
        return outBytes:Join(" ").
    }

    // HexToChar :: _hexStr<string>, _charPath<string> -> output<string>
    // Converts a 1,2, or 4-char hex string to the appropriate string char
    global function HexToChar
    {
        parameter _hexStr,
                  _charPath.

        return char(CharCodes:Chars[_charPath]:Hex[_hexStr]).
    }

    // HexToCharCode :: _hexStr<string>, _charPath<string> -> outStr<string>
    // Converts a hex string to the appropriate character code given the proper path context
    global function HexToCharCode
    {
        parameter _hexStr,
                  _charPath.

        local selPage to CharCodes.

        if selectedCharSet:HasKey(_hexStr)
        {
            return selectedCharSet:Hex[_hexStr].
        }
        else
        {
            return -1.
        }
    }

    // ByteToHex :: _byteMask<string> -> hexStr<string>
    global function ByteToHex 
    {
        parameter _byteMask.

        local hexStr to "".
        local bytes to _byteMask:Split(" ").
        
        for _byte in bytes
        {
            set hexStr to hexStr + BitMaskRef:Byte[_byte].
        }

        return hexStr.
    }
    // #endregion

    // *- Object helpers
    // #region

    // selexi :: _lex<Lexicon>, _pagePath<String> -> selPage
    // Safely returns whatever is found via the provided path following the "<parent/<child>/<etc>" format
    // Validates the path by walking it. Bails immediately if the path is not found
    global function selexi
    {
        parameter _lex,
                  _pagePath.

        local selPage to _lex.

        if selPage:Keys:Length > 0
        {
            if _pagePath:Contains("/")
            {
                for _leaf in _pagePath:Split("/")
                {
                    if selPage:HasKey(_leaf) 
                    {
                        set selPage to selPage[_leaf].
                    }
                    else
                    {
                        return selPage.
                    }
                }
            }
            else
            {
                set selPage to choose selPage[_pagePath] if selPage:HasKey(_pagePath) else selPage.
            }
        }
        return selPage.
    }
    // #endregion

    // *- State (Program / Runmode / Content) utilities
    // #region

    // CacheState
    global function cache_state {

        parameter _state is g_State.

        if g_StateCache:IsType("String") init_state_cache().
        
        g_StateCache:Clear.
        g_StateCache:Write(_state:join(",")).

        return Exists(g_StateCachePath).
    }

    // InitStateCache
    global function init_state_cache {

        parameter _resetState to False.

        local state to list(
            // "planID", // String plan id
            // ,0    // Context (current running program module)
            // ,0    // Program
            // ,0    // Runmode
            // ,0    // StageStop
        ).
        
        if exists(g_StateCachePath) and not _resetState
        {
            set g_StateCache to Open(g_StateCachePath).
            local stateCache to g_StateCache:ReadAll:String:Split(",").
            state:Add(stateCache[0]).

            from { local i to 1.} until i = stateCache:Length step { set i to i + 1.} do
            {
                 state:Add(stateCache[i]:ToNumber(0)).
            }
        }
        else
        {
            set state to list(g_MissionPlanID, 0, 0, 0, 0).
            log state:join(",") to g_StateCachePath.
            set g_StateCache to Open(g_StateCachePath).
        }
        
        set g_State         to state.

        set g_MissionPlanID to g_State[0]. // print g_MissionPlanID.
        set g_Context       to g_State[1]. // print g_Context.
        set g_Program       to g_State[2]. // print g_Program.
        set g_Runmode       to g_State[3]. // print g_RunMode.
        set g_StageLimit    to g_State[4]. // print g_StageLimit.

        return Exists(g_StateCachePath).
    }

    // ReadStateCache
    global function read_state_cache {

        if exists(g_StateCachePath)
        {
            return Open(g_StateCachePath):ReadAll:String:Split(",").
        }
        return list("", -1,-1,-1,0).
    }


    // SetContext
    global function set_context {

        parameter _context is 0,
                  _update is False.

        set g_Context to _context.
        if _update update_state().
        return g_Context.
    }

    // SetContext
    global function set_missionplan_id {

        parameter _planId is "NUL",
                  _update is False.

        set g_MissionPlanId to _planId.
        if _update update_state().
        return g_MissionPlanId.
    }


    // SetProgram
    global function set_program {

        parameter _prog is 0,
                  _update is False.

        set g_Program to _prog.
        set g_Runmode to 0.
        if _update update_state().
        ClearScreen.
        return g_Program.
    }

    // SetRunmode
    global function set_runmode {

        parameter _rm is 0,
                  _update is False.

        set g_Runmode to _rm.
        if _update update_state().
        return g_Runmode.
    }

    // SetStageStop
    global function set_stage_limit {

        parameter _stgStop is Stage:Number,
                  _update is False.

        set g_StageLimit to _stgStop.
        if _update update_state().
        return g_StageLimit.
    }


    // UpdateState
    global function update_state {

        parameter _cacheEnable to False.

        set g_State to list (
            g_MissionPlanID,
            g_Context,
            g_Program,
            g_Runmode,
            g_StageLimit
        ).

        if _cacheEnable 
        {
            cache_state().
        }
    }
    
    // #endregion

    
    // Addon Wrappers
    // #region

    // Career
    // #region
    // TryRecoverVessel :: [_ves<Ship>], [_recoveryWindow<Scalar>] -> <None>
    global function try_vessel_recovery
    {
        parameter _ves is Ship,
                  _recoveryDelay is 2,
                  _recoveryWindow is 20.

        if Addons:Available("Career")
        {
            local waitTimer to _recoveryDelay.
            set g_TS to Time:Seconds + waitTimer.
            local waitStr to "Waiting until {0,-5}s to begin recovery attempts".
            local g_TermChar to "".
            out_info("Press Enter to recover immediately, Backspace to abort").
            local abortFlag to false.
            local doneFlag to false.
            until Time:Seconds > g_TS or doneFlag
            {
                out_msg(waitStr:Format(Round(g_TS - Time:Seconds, 2))).
                set g_TermChar to get_term_char().

                if g_TermChar <> ""
                {
                    out_info().
                    if g_TermChar = Terminal:Input:Enter
                    {
                        set abortFlag to false.
                        set doneFlag to true.
                    }
                    else if g_TermChar = Terminal:Input:Backspace
                    {
                        set abortFlag to true.
                        set doneFlag to true.
                    }
                    else
                    {
                        out_info("Press Enter to recover immediately, Backspace to abort").
                    }
                    set g_TermChar to "".
                }
                wait 0.01.
            }

            if abortFlag 
            {
                out_msg("Aborting recovery attempts!").
                wait 0.25.
            }
            else
            {
                local getRecoveryState to { parameter __ves is Ship. if Addons:Career:IsRecoverable(__ves) { return list(True, "++REC").} else { return list(False, "UNREC").}}.
                local recoveryStr to "Attempting recovery (Status: {0})".
                set g_TS to Time:Seconds + _recoveryWindow.
                local abortStr to "Press any key to abort ({0,-5}s)".
                until Time:Seconds >= g_TS or abortFlag
                {
                    local recoveryState to getRecoveryState:Call(_ves).
                    if recoveryState[0]
                    {
                        Addons:Career:RecoverVessel(_ves).
                        out_msg("Recovery in progress (Status: {0})":Format(recoveryState[1])).
                        out_info().
                        wait 0.01.
                        break.
                    }
                    else
                    {
                        out_msg(recoveryStr:Format(recoveryState[1])).
                        out_info(abortStr:Format(g_TS - Time:Seconds, 2)).

                        set g_TermChar to get_term_char().
                        if g_TermChar <> ""
                        {
                            set abortFlag to true.
                        }
                        wait 0.01.
                    }
                }
                
                if abortFlag
                {
                    out_msg("Recovery aborted!").
                    out_info().
                }
                else
                {
                    out_msg("Recovery failed. :(").
                }
                out_info().
            }
        }
        else
        {
            out_msg("No recovery firmware found!").
            out_info().
            wait 0.25.
        }
    }

    // #endregion
    // #endregion

// #endregion