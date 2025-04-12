@LazyGlobal off.

// Vehicle Launch Control

// *~ Dependencies ~* //
// #region
// #include "0:/_lib/term.ks"
// #include "0:/_lib/engine.ks"
// #include "0:/_lib/control.ks"
// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region
    local __vlcPadStage    is Stage:Number.
    local __vlcTowerClrSpd is 20.
    local __vlcTowerHeight is Ship:Bounds:Size:Mag * 1.725.

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

    // Ascent phase execution
    // #region


    // launch_clear_tower
    // 
    global function launch_clear_tower
    {
        parameter _clrAlt is __vlcTowerHeight,
                  _clrSpd is __vlcTowerClrSpd.

        out_msg("Powered Liftoff").
        until Ship:Altitude >= _clrAlt and Ship:VerticalSpeed > _clrSpd
        {
            out_msg("Mission Clock   : T {0}":Format(Round(MissionTime, 2)), 1).
            if Stage:Number > StageStop
            {
                // local activeEngines to get_active_engines(Ship, "nosep").
                if Ship:AvailableThrust < 0.01 
                {
                    wait until Stage:Ready.
                    stage.
                }
                local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
                out_info("Alt: {0} | VSpd: {1}":Format(Round(Ship:Altitude), Round(Ship:VerticalSpeed, 1)), 2).
            }
            else
            {
                if Ship:AvailableThrust < 0.01 
                {
                    local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                    out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
                    out_info("Alt: {0} | VSpd: {1}":Format(Round(Ship:Altitude), Round(Ship:VerticalSpeed, 1)), 2).
                }
                else
                {
                    out_msg("Passive Coast").
                    out_info("Thrust: N/A", 1).
                    out_info("Alt: {0} | VSpd: {1}":Format(Round(Ship:Altitude), Round(Ship:VerticalSpeed, 1)), 2).
                }
            }
        }
        return Ship:Altitude.
    }

    // launch_pitch_program
    //
    global function launch_pitch_program
    {
        parameter _stgLim,
                  _steerDel is "",
                  _tgtPitAng is 0,
                  _transAltWindow is 2500,
                  _transStartAlt is Ship:Altitude,
                  _transStartPitch is pitch_for(Ship, Ship:Facing),
                  _maxPitDeviation is 4.25.

        local curAlt to 0.
        local nrmAlt to 0.

        local pitErr to 0.
        local outPit to 0.
        local tgtPit to 0.
        
        if _steerDel:IsType("String")
        {
            set _steerDel to { parameter _pit. return Heading(compass_for(Ship, Ship:Facing), _pit, 0).}.
            out_debug("_steerDel Type: {0}":Format(_steerDel:TypeName)).
        }

        local transEndAlt to _transStartAlt + _transAltWindow.

        local curPit     to _transStartPitch.
        local pitSpread to Abs(curPit - _tgtPitAng).
        
        until Ship:Altitude >= transEndAlt //  and Ship:VerticalSpeed >= _coverVSpd
        {
            out_msg("Mission Clock   : T {0}":Format(Round(MissionTime, 2)), 1).

            set curAlt to Ship:Altitude.
            set nrmAlt to curAlt - _transStartAlt.

            set curPit to Round(pitch_for(ship, Ship:Facing), 2).
            
            set pitErr to nrmAlt / _transAltWindow.
            set outPit to Round(_transStartPitch - (pitSpread * pitErr), 2).
            set tgtPit to min(curPit + _maxPitDeviation, max(outPit, curPit - _maxPitDeviation)).
            
            out_info("Pitch program: [Actual:{0,5}] [Cur:{1,5}] [Tgt: {2,5}] [{3,5}%]":Format(curPit, outPit, Round(_tgtPitAng, 2), Round(pitErr * 100, 2))).

            set SVal to _steerDel:Call(tgtPit).

            if Stage:Number > _stgLim
            {
                if Ship:AvailableThrust < 0.01 
                {
                    wait until Stage:Ready.
                    stage.
                }
                local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
                out_info("Alt: {0} | VSpd: {1}":Format(Round(Ship:Altitude), Round(Ship:VerticalSpeed, 1)), 2).
            }
            else
            {
                if Ship:AvailableThrust < 0.01 
                {
                    out_msg("Powered Ascent").
                    local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                    out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
                }
                else
                {
                    out_msg("Passive Coast").
                    out_info("",1).
                }
            }
        }
        return Ship:Altitude.
    }

    global function launch_gravity_turn
    {
        parameter _stgLim,
                  _steerDel is { parameter _pit is pitch_for(ship, Ship:SrfPrograde). return Heading(compass_for(Ship, Ship:Facing), _pit, 0).},
                  _proToUse is "auto", // "srf|surface", "obt|orbit"
                  _minPit is 1.25,
                  _endAlt is 0,
                  _endSpd is 0.

        local curPit    to 0.
        local obtProPit to 0.
        local outPit    to 0.
        local srfProPit to 0.
        local pitDelta  to 0.01325.

        local doneArmed to _endAlt > 0.
        local doneFlag  to false.

        until doneFlag
        {
            out_msg("Mission Clock   : T {0}":Format(Round(MissionTime, 2)), 1).
            set curPit    to Round(pitch_for(Ship, Ship:Facing), 2).
            set srfProPit to Round(pitch_for(Ship, Ship:SrfPrograde), 2).
            set obtProPit to Round(pitch_for(Ship, Ship:Prograde), 2).

            out_msg("{0}-Locked gravity turn":Format(_proToUse)).
            out_info("[Cur:{0,5}] [SrfPro:{1,5}] [ObtPro:{2,5}] ":Format(curPit, srfProPit, obtProPit)).
            
            local srfProDelta to Abs(curPit - srfProPit).
            local obtProDelta to Abs(curPit - obtProPit).

            if _proToUse:MatchesPattern("(obt|orbit)")
            {
                set outPit to max(_minPit, min(curPit, max(obtProPit, curPit - pitDelta))).
            }
            else if _proToUse:MatchesPattern("(srf|surface)")
            {
                set outPit to max(_minPit, min(curPit, max(srfProPit, curPit - pitDelta))).
            }
            else if _proToUse:MatchesPattern("auto")
            {
                if srfProDelta < obtProDelta
                {
                    set outPit to max(_minPit, min(curPit, max(srfProPit, curPit - pitDelta))).
                }
                else
                {
                    set outPit to max(_minPit, min(curPit, max(obtProPit, curPit - pitDelta))).
                }
            }
            set SVal to _steerDel:Call(outPit).

            if Stage:Number > _stgLim
            {
                // local activeEngines to get_active_engines(Ship, "nosep").
                if Ship:AvailableThrust < 0.01 
                {
                    wait until Stage:Ready.
                    stage.
                }
                local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
            }
            else
            {
                if Ship:AvailableThrust > 0 and Ship:Thrust > 0
                {
                    local thrPct to Round(Ship:Thrust / Ship:AvailableThrust) * 100.
                    out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
                }
                else if eta:apoapsis > eta:periapsis
                {
                    out_msg("Suborbital Trajectory").
                    out_info("",1).
                }
                else
                {
                    out_msg("Passive Coast").
                    out_info("",1).
                }
            }
            out_info("Alt: {0,-8} | SrfSpd: {1,-8} | ObtSpd: {2,-8}":Format(Round(Ship:Altitude), Round(Ship:Velocity:Surface:Mag, 2), Round(Ship:Velocity:Orbit:Mag, 2)), 2).

            if doneArmed
            {
                set doneFlag to Ship:Altitude >= _endAlt or Ship:Velocity:Surface:Mag >= _endSpd.
            }
        }
        return Ship:Altitude.
    }

    // #endregion

    // *- Coundown functions
    // #region

    // init_countdown :: ([_cdObj<lexicon>]) -> cdObj<lexicon>
    global function init_countdown
    {
        parameter _cdObj is lex(
            "CDBaseDur", 4.27,
            "CDTermDur", 0,
            "TermCountLex", lex(),
            "TermCountSeq", list(),
            "TermCountTS", list(),
            "LaunchTS", 4.27,
            "PadStage", get_pad_stage()
            ).

        out_info("init_countdown").
        
        // Create a shallow copy
        out_info("cdObj shallow copy", 1).
        local cdObj to _cdObj:Copy.

        // Get the pad stage.
        out_info("get_pad_stage", 1).
        set __vlcPadStage to get_pad_stage().
        set cdObj:PadStage to __vlcPadStage.

        // -- Get spool time for engines in launch stage
        out_info("get_burn_stage_engines", 1).
        local stgEngs to get_burn_stage_engines(Ship, __vlcPadStage + 1, true).

        local firstSpoolTime to 0.
        local firstSpoolStg  to 0.

        out_info("starting spool loop", 1).
        from { local i to stgEngs:Length - 1. } until i < 0 step { set i to i - 1.} do
        {
            local eng to stgEngs[i].
            local m to eng:GetModule("ModuleEnginesRF").

            local engIgnStg to eng:Stage.
            local spoolStr to "effective spool-up time".
            local spoolDur to Round(get_field(m, spoolStr, 0), 2).
            
            if cdObj:TermCountLex:HasKey(spoolDur)
            {
                if cdObj:TermCountLex[spoolDur]:HasKey("Stg")
                {
                    set cdObj:TermCountLex[spoolDur]:Stg to min(cdObj:TermCountLex[spoolDur]:Stg, engIgnStg).
                }
                else
                {
                    cdObj:TermCountLex[spoolDur]:Add("Stg", engIgnStg).
                }
            }
            else
            {
                cdObj:TermCountLex:Add(spoolDur, lex(
                    "Stg", engIgnStg
                    )
                ).
            }
            
            if spoolDur > firstSpoolTime
            {
                set firstSpoolTime to spoolDur.
                set firstSpoolStg  to max(firstSpoolStg, engIgnStg).
            }
        }

        local sortDel to { parameter _curVal, _chkVal. return _chkVal > _curVal. }.
        local cdTermDur to cdObj:CDBaseDur + firstSpoolTime.

        set cdObj["TermCountSeq"] to sort(cdObj:TermCountLex:Keys, sortDel@).
        set cdObj["CDTermDur"]   to cdTermDur.
        set cdObj["SetLaunchTS"] to { parameter _cdObj_, _startTime to Time:Seconds. local lnTS to _startTime + _cdObj_["CDTermDur"]. set _cdObj_:LaunchTS to lnTS. return _cdObj_.}.
        set cdObj["EngineStart"] to list(firstSpoolStg, firstSpoolTime).

        return cdObj.
    }

    // exec_term_countdown :: _cdSeqObj
    // Executes the countdown. Ignites engines if there are any to spool up
    global function exec_term_countdown
    {
        parameter _cdSeqObj.

        local ignSeqStart to false.
        local launchTS to _cdSeqObj:LaunchTS.

        for seqTime in _cdSeqObj:TermCountSeq
        {
            _cdSeqObj:TermCountTS:Add(launchTS - seqTime).
        }

        // out_debug("_cdSeqObj:TermCountTS: [{0}]":Format(_cdSeqObj:TermCountTS:Length), -6).
        // from { local i to -5. } until doneFlag or i >= min(_cdSeqObj:TermCountTS:Length, 4) step { set i to i + 1.} do
        // {
        //     for ts in _cdSeqObj:TermCountTS
        //     {
        //         out_debug("[{0}] TermCountTS> {1}":format(i, ts), i).
        //     }
        // }
        
        out_msg("Launch Countdown").
        from { local i to 0.} until i = _cdSeqObj:TermCountTS:Length step { set i to i + 1.} do
        {
            local seqTime to _cdSeqObj:TermCountSeq[i].
            local seqTs   to _cdSeqObj:TermCountTS[i].
            out_info("Ignition sequence armed").
            
            until Time:Seconds > seqTS
            {
                out_msg("Launch Countdown: T-{0}":Format(Round(launchTS - Time:Seconds, 2))).
            }

            out_msg("Launch Countdown: T-{0}":Format(Round(launchTS - Time:Seconds, 2))).
            out_info("Ignition sequence start").

            // out_debug("termcountlex:keys: {0}":Format(_cdSeqObj:TermCountLex:Keys:Join(";"))).
            set TVal to 1.
            set ignSeqStart to staged_engine_ignition(_cdSeqObj:TermCountLex[seqTime]:Stg).
            
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            out_info("Vehicle Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }
        out_info("Engine ignition sequence active").
        // Final phase
        until Time:Seconds > launchTS
        {
            out_msg("Launch Countdown: T-{0}":Format(Round(launchTS - Time:Seconds, 2))).
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            out_info("Vehicle Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }
        return ignSeqStart.        
    }

    // hold_term_countdown
    global function terminal_countdown_hold
    {
        parameter _cdSeqObj is lex().

        out_msg(" *** TERMINAL PHASE HOLD *** ").
        out_msg("* Press [ENTER] to resume countdown *", 1).
        local beginTermPhase to false.
        local tchar to "".
        until beginTermPhase
        {
            local curTime to time:seconds.

            out_info("LaunchTS: +{0}":Format(round(_cdSeqObj:LaunchTS + curTime)), 1).
            out_info("CurTS   :  {0}":Format(round(curTime, 1), 2), 2).

            set tchar to get_term_char().

            if tchar <> ""
            {
                if tchar = terminal:Input:Enter
                {
                    set beginTermPhase to true.
                }
                else
                {
                    out_info("incorrect key", 3).
                    wait 0.05.
                }
            }
        }
        return true.
    }
    
    
    // #endregion

    // *- Launch Commit
    // #region

    // eval_launch_commit_condition :: _minThrPct<decimal>.
    // Checks whether the vessel's thrust as a percentage of available thrust is above the min value for launch
    global function eval_launch_commit_thrust
    {
        parameter _minThrPct is 0.9875.

        local thrErr to choose round(Ship:thrust / Ship:AvailableThrust, 4) if Ship:Thrust > 0 else 0.
        local launchCommitGo to thrErr >=_minThrPct.
        
        out_info("Launch Commit: {0} ":Format(launchCommitGo)).
        local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust, 4) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
        out_info("Thrust: {0} [{1,5}%/{2,5}%]":Format(Round(Ship:Thrust, 2), thrPct, Round(_minThrPct * 100, 2)), 1).

        return launchCommitGo.
    }

    // launch_commit_go :: _padStg, _minThrPct -> <bool> 
    // Stages the clamps
    global function launch_commit_go
    {
        parameter _padStg is get_pad_stage(),
                  _launchTS is 0.

        until Stage:Number = _padStg
        {
            out_info("Launch Commit: {0} ":Format(true)).
            until Stage:Ready
            {
                local launchDiff to choose Round(missionTime, 2) if _launchTS = 0 else Round(Time:Seconds - _launchTS, 2).
                
                out_msg("Mission Clock   : T {0}":Format(launchDiff), 1).

                local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust, 4) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
                out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct), 1).
            }
            stage.
        }
        out_info("Releasing clamps").
        out_msg("Liftoff").

        return true.
    }

    // #endregion

    // *- Launchpad functions
    // #region
    
    // get_pad_stage :: ([_startStg<int>]) -> padStage<Int>
    // Returns the stage number of the launch pad/clamps
    global function get_pad_stage
    {
        parameter _startStg is Stage:Number.

        local padStage to _startStg.
        for m in Ship:ModulesNamed("LaunchClamp")
        { 
            set padStage to min(padStage, m:Part:Stage).
        }
        return padStage.
    }
    
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
    // #endregion

// #endregion