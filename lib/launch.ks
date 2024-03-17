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
    // #endregion

    // *- Global
    // #region
    
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


        print "ALT     : {0}   ":Format(Round(Ship:Altitude)) at (0, g_line).
        print "VERTSPD : {0}   ":Format(Round(Ship:VerticalSpeed, 1)) at (0, cr()).
        print "GRNDSPD : {0}   ":Format(Round(Ship:Groundspeed, 1)) at (0, cr()).

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