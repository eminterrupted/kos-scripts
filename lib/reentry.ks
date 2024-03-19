// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    global g_RecoveryFlag to false.
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

//  *- Parachutes
// #region

    // ArmParachutes
    global function ArmParachutes
    {
        parameter _chuteList to Ship:ModulesNamed("RealChuteModule").

        for ch in _chuteList
        {
            DoEvent(ch, "arm parachute").
        }
    }

// #endregion

//  *- Display
// #region

    // DispDescentTelemtry :: Input / Output
    // Displays telemetry related to descending towards a surface
    global function DispDescentTelemetry
    {
        parameter _line is g_line.

        set g_line to _line.

        print "ALT (SL)  : {0,-9}":Format(Round(Ship:Altitude, 1)):PadRight(g_termW - 21)                               at (0, g_line).
        print "ALT (RDR) : {0,-9}":Format(Round(Alt:Radar, 1)):PadRight(g_termW - 21)                                   at (0, cr()).
        print "SRF SPEED : {0,-5}":Format(Round(Velocity:Surface:Mag, 1)):PadRight(g_termW - 17)                        at (0, cr()).
        print "VERT SPEED: {0,-5}":Format(Round(VerticalSpeed, 1)):PadRight(g_termW - 17)                               at (0, cr()).
        print "GRND SPEED: {0,-5}":Format(Round(Ship:GroundSpeed, 1)):PadRight(g_termW - 17)                            at (0, cr()).
        print "ATM PRESS : {0,-10}":Format(Round(Body:Atm:AltitudePressure(Ship:Altitude), 5)):PadRight(g_termW - 21)   at (0, cr()).
    }

// #endregion

//  *- Recovery
// #region

    // TryRecoverVessel :: [_ves<Ship>], [_recoveryWindow<Scalar>] -> <None>
    global function TryRecoverVessel
    {
        parameter _ves is Ship,
                _recoveryWindow is 30.

        if Addons:Available("Career")
        {
            set g_line to 4.
            local getRecoveryState to { parameter __ves is Ship. if Addons:Career:IsRecoverable(__ves) { return list(True, "RECOVERING").} else { return list(False, "UNRECOVERABLE").}}.
            set g_RecoveryFlag to true.
            
            if g_TS = 0 
            {
                set g_TS to Time:Seconds + _recoveryWindow.
            }
            
            if Time:Seconds >= g_TS
            {
                local recoveryState to getRecoveryState:Call(_ves).
                print "Attempting recovery":Format(recoveryState[1]):PadRight(g_termW - 15) at (0, cr()).
                if recoveryState[0]
                {
                    Addons:Career:RecoverVessel(_ves).
                    
                    print "Recovery in progress (Status: {0})":Format(recoveryState[1]):PadRight(g_termW - 15) at (0, cr()).
                    clr(cr()).
                    wait 0.01.
                }
                else
                {
                    print "Recovery in progress (Status: {0})":Format(recoveryState[1]):PadRight(g_termW - 15) at (0, cr()).
                    print "Time remaining for recovery: {0}s":Format(g_TS - Time:Seconds):PadRight(g_termW - 15) at (0, cr()).

                    GetTermChar().
                    if g_TermChar <> ""
                    {
                        set g_RecoveryFlag to false.
                    }
                    wait 0.01.
                }
            }
        }
        else
        {
            print "No recovery firmware found!":PadRight(g_termW - 15) at (0, cr()).
            clr(cr()).
            clr(cr()).
            wait 0.25.
            set g_RecoveryFlag to false.
        }
        return false.
    }

// #endregion



// #endregion