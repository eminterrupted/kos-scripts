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
    local l_PitLim to 30.

    local l_PitchProgram_StartAlt   to 125.
    local l_PitchProgram_EndAlt     to 70000.
    local l_PitchTransitionWindow   to l_PitchProgram_EndAlt - l_PitchProgram_StartAlt.
    
    local l_SrfProToObtPro_StartAlt to 2500.
    local l_SrfProToObtPro_EndAlt   to 75000.
    local l_ProTransitionWindow     to l_SrfProToObtPro_EndAlt - l_SrfProToObtPro_StartAlt.
    // #endregion

    // *- Global
    // #region
    global g_AzData to list().
    global g_DRTurnStartAlt to 125.
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
                _line is 10,
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

        local adjAltErr            to 0.
        local adjPitLim            to 0.
        local curAlt               to Ship:Altitude.
        local curAltErr            to curAlt / l_PitchProgram_EndAlt.
        local curAltPres           to Body:Atm:AltitudePressure(curAlt).
        local curApoErr            to _curApo / _tgtApo.
        local curEffErr            to 0.
        local curProAltErr         to (curAlt - l_SrfProToObtPro_StartAlt) / l_ProTransitionWindow.
        local curTurnAltErr        to (curAlt - l_PitchProgram_StartAlt) / l_PitchTransitionWindow.

        local curProPit to Ship:Facing.
        local obtProPit to pitch_for(Ship, Ship:Prograde).
        local obtProPitAdj to obtProPit.
        local srfProPit to pitch_for(Ship, Ship:SrfPrograde).
        local srfProPitAdj to srfProPit.
        
        // local tgtAltPitAng          to 0.

        // local selectedPit to choose srfProPitAdj if srfProPitAdj > obtProPit else obtProPit.

        if curAlt < l_SrfProToObtPro_StartAlt
        {
            set curProPit to srfProPit.
            set curEffErr to curAltErr.
        }
        else if curAlt < l_SrfProToObtPro_EndAlt
        {
            set curProPit to (obtProPit * curProAltErr) + (srfProPit * (1 - curProAltErr)).
            set curEffErr to (curAltErr * (1 - curTurnAltErr)) + (curApoErr * curTurnAltErr).
        }
        else
        {
            set curProPit to obtProPit.
            set curEffErr to curApoErr.
        }

        // local curProPit to choose srfProPitAdj if curAlt < l_SrfProToObtPro_Alt
        //                 else choose (srfProPitAdj + obtProPitAdj) / 2 if curAlt < l_TransAlt // ((srfProPit + obtProPit) / 2) if curApo < 62500
        //                 else obtProPit.
        // local facingPit to pitch_for(Ship, Ship:Facing).

        local tgtRawAng     to 90 * (1 - curEffErr).
        local tgtShapedAng  to tgtRawAng * _shaper.
        local tgtPitAngNrm  to Min(90, Max(-22.5, tgtShapedAng)).
        set   adjPitLim     to Max(1.25, l_PitLim * (1 - curAltPres)).
        local effPitAng     to Max(curProPit - adjPitLim, Min(tgtPitAngNrm, curProPit + adjPitLim)).
        // local effPitAng     to Max(curProPit - l_PitLim, Min(tgtAltPitAng, curProPit + l_PitLim)) * _shaper.

        // if effPitAng < 0 
        // {
        //     set effPitAng to effPitAng.
        // }
        
        local lastLine to g_Line.
        
        set g_Line to 25.

        print "PIT (FACING) : {0}":Format(Round(pitch_for(ship, Ship:Facing), 2)) at (0, g_Line).
        print "PIT (TGT RAW): {0}":Format(Round(tgtRawAng, 2)) at (0, cr()).
        print "PIT (TGT SHP): {0}":Format(Round(tgtShapedAng, 2)) at (0, cr()).
        print "PIT (TGT NRM): {0}":Format(Round(tgtPitAngNrm, 2)) at (0, cr()).
        print "PITLIM (ADJ) : {0}":Format(Round(adjPitLim, 2)) at (0, cr()).
        print "PIT (EFF OUT): {0}":Format(Round(effPitAng, 2)) at (0, cr()).

        set g_Line to lastLine.

        if g_LogOut log "{0},{1},{2},{3},{4},{6},{7},{8},{9},{10},{11},{12},{13},{14}":Format(MissionTime, effPitAng, adjPitLim, curAltPres, tgtPitAngNrm,curAlt, curAltErr, curApoErr, curEffErr, curTurnAltErr, curProPit, obtProPit, obtProPitAdj, srfProPit, srfProPitAdj) to g_DataLog.

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
    
// #endregion
// #endregion