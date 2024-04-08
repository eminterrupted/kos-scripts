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
    global g_RCSDisableAlt  to 25000.
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
            local waitTimer to 2.
            set g_TS to Time:Seconds + waitTimer.
            local waitStr to "Waiting until {0,-5}s to begin recovery attempts".
            set g_TermChar to "".
            OutMsg("Press any key to abort", cr()).
            local abortFlag to false.
            local line to g_Line.

            until Time:Seconds > g_TS or abortFlag
            {
                set g_Line to line.
                GetTermChar().
                if g_TermChar <> ""
                {
                    set abortFlag to true.
                    clr(cr()).
                    set g_Line to line.
                }
                else
                {
                    OutInfo(waitStr:Format(Round(g_TS - Time:Seconds, 2)), cr()).
                }
                wait 0.01.
            }

            if abortFlag 
            {
                OutMsg("Aborting recovery attempts!", cr()).
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
                    set g_Line to line.

                    local recoveryState to getRecoveryState:Call(_ves).
                    if recoveryState[0]
                    {
                        Addons:Career:RecoverVessel(_ves).
                        OutInfo("Recovery in progress (Status: {0})":Format(recoveryState[1]), cr()).
                        clr(cr()).
                        wait 0.01.
                        break.
                    }
                    else
                    {
                        OutInfo(recoveryStr:Format(recoveryState[1]), cr()).
                        OutStr(abortStr:Format(g_TS - Time:Seconds, 2), cr()).

                        GetTermChar().
                        if g_TermChar <> ""
                        {
                            set abortFlag to true.
                        }
                        wait 0.01.
                    }
                }
                
                if abortFlag
                {
                    OutMsg("Recovery aborted!", cr()).
                    clr(cr()).
                }
                else
                {
                    OutMsg("Recovery failed. :(", cr()).
                }
                clr(cr()).
            }
        }
        else
        {
            OutMsg("No recovery firmware found!", cr()).
            clr(cr()).
            wait 0.25.
        }
    }

    // TryRecoverVessel_Old :: [_ves<Ship>], [_recoveryWindow<Scalar>] -> <None>
    // This doesn't work
    global function TryRecoverVessel_Old
    {
        parameter _ves is Ship,
                _recoveryWindow is 30.

        if Addons:Available("Career")
        {
            set g_line to g_line + 5.
            local getRecoveryState to { parameter __ves is Ship. if Addons:Career:IsRecoverable(__ves) { return list(True, "RECOVERING").} else { return list(False, "UNRECOVERABLE").}}.
            set g_RecoveryFlag to true.
            
            if g_TS = 0 
            {
                set g_TS to Time:Seconds + _recoveryWindow.
            }
            
            if Time:Seconds >= g_TS
            {
                local recoveryState to getRecoveryState:Call(_ves).
                OutMsg("Attempting recovery":Format(recoveryState[1]):PadRight(g_termW - 15), cr()).
                if recoveryState[0]
                {
                    Addons:Career:RecoverVessel(_ves).
                    
                    OutInfo("Recovery in progress (Status: {0})":Format(recoveryState[1]):PadRight(g_termW - 15), cr()).
                    clr(cr()).
                    wait 0.01.
                }
                else
                {
                    OutInfo("Recovery in progress (Status: {0})":Format(recoveryState[1]):PadRight(g_termW - 15), cr()).
                    OutStr("Time remaining for recovery: {0}s":Format(g_TS - Time:Seconds):PadRight(g_termW - 15), cr()).

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
            OutMsg("No recovery firmware found!":PadRight(g_termW - 15), cr()).
            clr(cr()).
            clr(cr()).
            wait 0.25.
            set g_RecoveryFlag to false.
        }
        return false.
    }

// #endregion



// #endregion