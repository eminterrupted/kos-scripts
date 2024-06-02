// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_Countdown_Base to 5.
    local l_PitchLimit to 30.
    local l_PitchChangeLimit to 5.
    local l_PitchUpperMax to 17.5.

    local l_PitchMax        to 90.
    local l_PitchMin        to -27.

    local l_PitchProgram_StartAlt   to 50.
    local l_PitchProgram_EndAlt     to 70000.
    local l_PitchTransitionWindow   to l_PitchProgram_EndAlt - l_PitchProgram_StartAlt.
    
    local l_SrfProToObtPro_StartAlt to 2500.
    local l_SrfProToObtPro_EndAlt   to 75000.
    local l_ProTransitionWindow     to l_SrfProToObtPro_EndAlt - l_SrfProToObtPro_StartAlt.

    local l_MaxTransferAlt to 3000000.
    local l_MinTransferAlt to 140000.

    local l_PIDp to 0.00325.
    local l_PIDi to 0.0005.
    local l_PIDd to 0.002.
    local l_ApoPID to PidLoop(l_PIDp, l_PIDi, l_PIDd, -l_PitchChangeLimit, l_PitchChangeLimit).
    local l_ApoPIDSet to false.

    // #endregion

    // *- Global
    // #region
    global g_AzData to list().
    global g_DRTurnStartAlt to Ship:Bounds:Size:Z * 1.625.
    global g_PitchMinSpeed to 35.
    global g_PitchLimit to l_PitchLimit.
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

//  *- Display
// #region

    // TODO: DispLaunchTelemetry (Need to finish this)
    global function DispLaunchTelemetry
    {
        parameter _data is list(),
                _line is g_line,
                _widthConstraint is Terminal:Width - 2.

        set g_line to _line.

        local bt to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else -1.

        print "ALT     : {0}   ":Format(Round(Ship:Altitude)) at (0, g_line).
        print "VERTSPD : {0}   ":Format(Round(Ship:VerticalSpeed, 1)) at (0, cr()).
        print "GRNDSPD : {0}   ":Format(Round(Ship:Groundspeed, 1)) at (0, cr()).
        print "BT RMNG : {0}   ":Format(Round(bt, 2)) at (0, cr()).
        
    }

// #endregion

//  *- Launch ascent angle
// #region

    // GetAscentAngle :: Input / Output
    // Description
    global function GetAscentAngle
    {
        parameter _tgtApo,
                  _shaper to 1,
                  _curApo is Ship:Apoapsis.

        local adjAltErr     to 0.
        local adjPitLim     to 0.
        local curAlt        to Ship:Altitude.
        local curAltErr     to curAlt / l_PitchProgram_EndAlt.
        local curAltPres    to Body:Atm:AltitudePressure(curAlt).
        local curApoErr     to _curApo / _tgtApo.
        local curEffErr     to 0.
        local curProAltErr  to (curAlt - l_SrfProToObtPro_StartAlt) / l_ProTransitionWindow.
        local curTurnAltErr to (curAlt - l_PitchProgram_StartAlt) / l_PitchTransitionWindow.

         
        local tgtTransAlt   to Max(l_MinTransferAlt, _tgtApo * (1 - ((_tgtApo / 3.25) / l_MaxTransferAlt))).
        local curTransErr   to _curApo / tgtTransAlt. 

        local curFacePit to pitch_for(Ship, Ship:Facing).
        local selProPit to curFacePit.
        local obtProPit to pitch_for(Ship, Ship:Prograde).
        local obtProPitAdj to obtProPit.
        local srfProPit to pitch_for(Ship, Ship:SrfPrograde).
        local srfProPitAdj to srfProPit.

        local effPitAng     to curFacePit.

        // local tgtAltPitAng          to 0.

        // local selectedPit to choose srfProPitAdj if srfProPitAdj > obtProPit else obtProPit.

        if _curApo < (tgtTransAlt * 0.9875)
        {
            if curAlt < l_SrfProToObtPro_StartAlt
            {
                OutInfo("PitchMode: 0", g_line).
                set selProPit to srfProPit.
                set curEffErr to curAltErr.
            }
            else if curAlt < l_SrfProToObtPro_EndAlt
            {
                OutInfo("PitchMode: 1", g_line).
                set selProPit to (obtProPit * curProAltErr) + (srfProPit * (1 - curProAltErr)).
                if _curApo < tgtTransAlt
                {
                    set curEffErr to (curAltErr * (1 - curTurnAltErr)) + (curTransErr * curTurnAltErr).
                }
                else
                {
                    set curEffErr to (curAltErr * (1 - curTurnAltErr)) + (curApoErr * curTurnAltErr).
                    set l_PitchMin to Min(l_PitchMin, Max(-l_PitchLimit, l_PitchUpperMax + (-l_PitchMin * (1 - curEffErr)))).
                }
            }
            else
            {
                OutInfo("PitchMode: 2", g_line).
                set selProPit to obtProPit.
                set curEffErr to curTransErr.
                set l_PitchMin to Min(l_PitchMin, Max(-l_PitchLimit, l_PitchUpperMax + (-l_PitchMin * (1 - curEffErr)))).
            }

            local tgtRawAng     to 90 * (1 - curEffErr).
            local tgtShapedAng  to tgtRawAng * _shaper.
            local tgtPitAngNrm  to Min(l_PitchMax, Max(l_PitchMin, tgtShapedAng)).
            set   adjPitLim     to Max(0.125, l_PitchLimit * (1 - curAltPres)).
            set   effPitAng     to Max(selProPit - adjPitLim, Min(tgtPitAngNrm, selProPit + l_PitchUpperMax)).
        }
        else if not l_ApoPIDSet
        {
            OutInfo("PitchMode: 3", g_line).
            set selProPit to obtProPit.
            set l_PitchMax to 17.5.
            set l_PitchMin to -22.5.
            set l_ApoPID to PidLoop(l_PIDp, l_PIDi, l_PIDd, l_PitchMin, l_PitchMax).
            set l_ApoPID:Setpoint to Round(_tgtApo).
            set l_ApoPIDSet to True.
        }
        else
        {
            if g_TermChar:Length > 0
            {
                if Unchar(g_TermChar) = 112
                {
                    set l_ApoPID:kP to l_ApoPID:kP * 0.91.
                }
                else if Unchar(g_TermChar) = 80
                {
                    set l_ApoPID:kP to l_ApoPID:kP * 1.1.
                }
                else if Unchar(g_TermChar) = 105
                {
                    set l_ApoPID:kI to l_ApoPID:kI * 0.91.
                }
                else if Unchar(g_TermChar) = 73
                {
                    set l_ApoPID:kI to l_ApoPID:kI * 1.1.
                }
                else if Unchar(g_TermChar) = 100
                {
                    set l_ApoPID:kD to l_ApoPID:kD * 0.91.
                }
                else if Unchar(g_TermChar) = 68
                {
                    set l_ApoPID:kD to l_ApoPID:kD * 1.1.
                }
            }

            OutInfo("PitchMode: 4", g_line).
            
            // set   pidPitchDeflect to l_ApoPID:Update(Time:Seconds, _curApo).
            set   selProPit to obtProPit.
            // set   effPitAng to Min(l_PitchMax, Max(curFacePit + pidPitchDeflect, l_PitchMin)).
            set effPitAng to l_ApoPID:Update(Time:Seconds, _curApo).
            
            OutInfo("PID Setpoint: {0}":Format(l_ApoPID:Setpoint)).
            OutInfo("PID kP | kI | kD: {0} | {1} | {2}":Format(l_ApoPID:kP, l_ApoPID:kI, l_ApoPid:kD)).
            // OutInfo("PID Value: {0}":Format(Round(effPitAng, 2))).
            cr(). 
        }
        // else
        // {
        //     set selProPit to obtProPit.
        //     set curEffErr to (curApoErr + curTransErr) / 2.
        //     set pitMin to Min(pitMin, Max(-l_PitLim, l_PitchUpperMax + (pitMin * (1 - curEffErr)))).
        // }

        // local curProPit to choose srfProPitAdj if curAlt < l_SrfProToObtPro_Alt
        //                 else choose (srfProPitAdj + obtProPitAdj) / 2 if curAlt < l_TransAlt // ((srfProPit + obtProPit) / 2) if curApo < 62500
        //                 else obtProPit.
        // local facingPit to pitch_for(Ship, Ship:Facing).

        
        // local effPitAng     to Max(curProPit - l_PitLim, Min(tgtAltPitAng, curProPit + l_PitLim)) * _shaper.

        // if effPitAng < 0 
        // {
        //     set effPitAng to effPitAng * 1.5.
        // }
        
        local lastLine to g_Line.
        
        set g_Line to 25.

        OutStr("PIT (FACING)  : {0} ":Format(Round(curFacePit, 2)), g_Line).
        // OutStr("PIT (TGT RAW): {0}":Format(Round(tgtRawAng, 2)), cr()).
        // OutStr("PIT (TGT SHP): {0}":Format(Round(tgtShapedAng, 2)), cr()).
        // OutStr("PIT (TGT NRM): {0}":Format(Round(tgtPitAngNrm, 2)), cr()).
        // OutStr("PITLIM (ADJ) : {0}":Format(Round(adjPitLim, 2)), cr()).
        OutStr("PIT (EFF OUT) : {0} ":Format(Round(effPitAng, 2)), cr()).
        OutStr("PIT (OUT DIFF): {0} ":Format(Round(curFacePit - effPitAng, 2))).
        OutStr("PIT (FACE PRO): {0} ":Format(Round(curFacePit - selProPit, 2))).

        set g_Line to lastLine.

        if g_LogOut log "{0},{1},{2},{3},{4},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15}":Format(MissionTime, effPitAng, adjPitLim, curAltPres, curAlt, curAltErr, _curApo, curApoErr, curEffErr, curTurnAltErr, selProPit, obtProPit, obtProPitAdj, srfProPit, srfProPitAdj) to g_DataLog.

        return effPitAng.
    }

// #endregion

//  *- Pre-launch setup
// #region

    // GetCountdownTimers :: [(__meSpool)<type>] -> <list>(countdown timers)
    // Returns a list of timers needed to execute a launch countdown
    // Accepts an optional __meSpool parameter for the engine ignition timer offset
    global function GetCountdownTimers
    {
        parameter __meSpool is 0.

        local countdownStart to Time:Seconds.
        local launchTS       to countdownStart + l_Countdown_Base.
        local ignitionStart  to launchTS - __meSpool.

        return list(
            countdownStart // UT Timestamp of the start of the countdown
            ,launchTS      // UT Timestamp of 
            ,ignitionStart
        ).
    }

    // GetPrelaunchCrewCapacity
    global function GetPrelaunchCrewCapacity
    {
        local crewCap to Ship:CrewCapacity.

        if crewCap > 0
        {
            for p in Ship:PartsNamedPattern("^AM.MLP.*")
            {

            }
        }
    }

    // PrepLaunchPad
    // Method that will prep the launch pad (retract and set various parts) for imminent launch
    global function PrepLaunchPad
    {
        // Retract the crew arm first
        local crewArms to Ship:PartsNamedPattern("^AM.MLP.*Crew.*Arm.*").
        local modList to list().
        

        local _line to g_Line.
        if Ship:CrewCapacity > 0 and crewArms:Length > 0
        {
            OutMsg("Moving CrewArms").

            // Retract
            local actionName  to "toggle".
            local checkName   to "horizontal adjust".
            for p in crewArms
            {
                from { local i to 0.} until i = p:AllModules:Length step { set i to i + 1.} do
                {
                    local m to p:GetModuleByIndex(i).
                    if m:HasField(checkName) and m:HasAction(actionName)
                    {
                        modList:Add(m).
                        DoAction(m, actionName).
                    }
                }
            }
            wait 0.1.

            local doneInt to 1.
            until doneInt = 0
            {
                set doneInt to 0.
                set g_Line to _line.
                for m in modList
                {
                    OutInfo("{0}_{1}: {2}":Format(m:Part:Name, m:Part:CID, m:GetField("status")), cr()).
                    local stateInt to choose 1 if GetField(m, "status"):MatchesPattern("Moving\.*") else 0.
                    set doneInt to doneInt + stateInt.
                }
                if doneInt = 0
                {
                    for m in modList 
                    {
                        clr(cr()).
                    }
                }
            }
            wait 1.

            // Rotate
            set modList to list().

            set checkName  to "retraction limit".
            set actionName to "retract crew arm".
            local eventName to "retract arm".
            for p in crewArms
            {
                from { local i to 0.} until i = p:AllModules:Length step { set i to i + 1.} do
                {
                    local m to p:GetModuleByIndex(i).
                    if m:HasAction(actionName)
                    {
                        modList:Add(m).
                        DoAction(m, actionName).
                    }
                    else 
                    {
                        DoEvent(m, eventName).
                    }
                }
            }
            wait 0.1.

            set doneInt to 1.
            until doneInt = 0
            {
                set doneInt to 0.
                set g_Line to _line.
                for m in modList
                {
                    OutInfo("{0}_{1}: {2}":Format(m:Part:Name, m:Part:CID, m:GetField("status"))).
                    local stateInt to choose 1 if GetField(m, "status"):MatchesPattern("Moving\.*") else 0.
                    set doneInt to doneInt + stateInt.
                }
                if doneInt = 0
                {
                    for m in modList 
                    {
                        clr(cr()).
                    }
                }
            }
            wait 1.
        }
    }
    
// #endregion

// *- Launch Events
// #region

    // RetractSwingArms :: [(__armList)<List>] -> <none>
    // Retracts the provided list of tower arms. Defaults __armList to all arms found.
    global function RetractSwingArms
    {
        parameter __armList is Ship:PartsNamedPattern("SwingArm"),
                  __swingDir is 1.
        
        set __swingDir to Min(1, Max(0, __swingDir)).
        local swingStr to choose "retract arm right" if __swingDir = 1 else "retract arm left".

        for p in __armList
        {
            local modList to p:AllModules.
            local hitCount to 0.
            from { local i to 0.} until i = modList:Length or hitCount > 1 step { set i to i + 1.} do
            {
                local m to p:GetModuleByIndex(i).
                if m:Name = "ModuleAnimateGenericExtra"
                {
                    if m:HasField("arm length adjust") and hitCount = 2
                    {
                        set hitCount to hitCount + 1.
                        DoAction(m, "toggle").
                    }
                    else if m:HasEvent(swingStr)
                    {
                        set hitCount to hitCount + 2.
                        DoEvent(m, swingStr).
                    }
                }
            }
        }
    }
    
// #endregion

// #endregion