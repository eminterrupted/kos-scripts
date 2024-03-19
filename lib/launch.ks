// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_Countdown_Base to 3.
    local l_PitLim to 5.
    // #endregion

    // *- Global
    // #region
    global g_DRTurnStartAlt to 250.
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
        parameter _tgtAlt,
                  _curAlt is Ship:Altitude,
                  _shaper to 0.9925.

        local obtProPit to pitch_for(Ship, Ship:Prograde).
        local srfProPit to pitch_for(Ship, Ship:SrfPrograde).
        
        local curPitAng to choose srfProPit if _curAlt < 25000
                        else choose ((srfProPit + obtProPit) / 2) if _curAlt < 62500
                        else obtProPit. 
                        
        local cur_AltErr to _curAlt / _tgtAlt.
        
        local tgtAltPitAng to Min(90, Max(-15, 90 * (1 - cur_AltErr))).  
        local effPitAng to max(curPitAng - l_PitLim, min(tgtAltPitAng, curPitAng + l_PitLim)) * _shaper.
        if effPitAng < 0 
        {
            set effPitAng to effPitAng / 0.975.
        }
        
        print "Current Pitch Angle: {0}":Format(Round(effPitAng, 2)) at (0, cr()).

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