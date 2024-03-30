@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/reentry.ks").

// Declare Variables
local fairings      to list().
local fairJettAlt   to 10000.
local preDeployAlt  to 2000.
local stgTimeGoGo   to 5.
local tgtReentryAlt to 140000.
local warpZeroAlt   to 25.

// Parse Params
if params:length > 0 
{
  set tgtReentryAlt to params[0].
}

set g_Line to 4.
local steerDel to { return Ship:SrfRetrograde.}.
set g_Steer to steerDel:Call().

until Ship:Altitude <= 142500
{
    print "PASSIVE START - WAITING TO 142500 " at (0, g_Line). 
}

// set g_Steer to Ship:Facing.
lock steering to g_Steer.
local steerActive to true.

set fairings to Ship:PartsTaggedPattern("((Reentry|Descent)\|Fairing)|(Fairing\|(Reentry|Descent))").
if fairings:length > 0
{
    local fairingTags to fairings[0]:Tag:Split("|").
    if fairingTags:Length > 2 
    {
        set fairJettAlt to ParseStringScalar(fairings[0]:Tag:Split("|")[2], fairJettAlt).
    }
}

InitStateCache().
SetStageLimit(2).

until g_Program > 199 or g_Abort
{
    set g_Line to 4.

    if g_Program < 40
    {
        SetProgram(40).
    }

    // Position to retrograde
    else if g_Program = 40
    {
        if g_RunMode = 1
        {
            set steerDel to { return Ship:SrfRetrograde. }.
            set g_TS to Time:Seconds + 10.
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {
            if Time:Seconds >= g_TS 
            {
                set g_TS to 0.
                SetProgram(42).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "WAIT FOR AP":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
        print "AP ETA: T{0}  ":Format(Round(ETA:Apoapsis, 2)) at (0, cr()).
    }

    // Wait until apoapsis
    else if g_Program = 42
    {
        if g_RunMode > 0
        {
            if ETA:Apoapsis <= 5 or ETA:Apoapsis > ETA:Periapsis
            {
                clr(cr()).
                if warp > 0 set warp to 0.
                wait until Kuniverse:TimeWarp:IsSettled.
                SetProgram(44).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "WAIT FOR AP":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
        print "AP ETA: T{0}  ":Format(Round(ETA:Apoapsis, 2)) at (0, cr()).
    }

    // Stage to limit
    else if g_Program = 44
    {
        if g_RunMode > 0
        {
            if Stage:Number > g_StageLimit
            {
                if Stage:Ready stage.
            }
            else
            {
                SetProgram(46).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* STAGING *":PadRight(g_termW - 11) at (0, cr()).
            SetRunmode(1).
        }
        
    }

    // Arm Chutes
    else if g_Program = 46
    {
        if g_RunMode < 2
        {
            ArmParachutes().
            SetProgram(48).
        }
        else if g_RunMode < 3
        {
            print "* CHUTE(S) ARMED *":PadRight(g_termW - 18) at (0, cr()).
            SetProgram(48).            
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* ARMING CHUTE(S) *":PadRight(g_termW - 20) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Wait for reentry alt
    else if g_Program = 48
    {
        if g_RunMode > 0
        {
            if Ship:Altitude <= tgtReentryAlt
            {
                SetRunmode(3).
                if Ship:ModulesNamed("ModuleRCSFX"):Length > 0
                {
                    set steerDel to { return Ship:SrfRetrograde.}.
                    if Time:Seconds > stgTimeGoGo
                    {
                        SetProgram(50).
                    }
                }
                else
                {
                    SetRunmode(5).
                    until Stage:Number = 1
                    {
                        if Stage:Ready stage.
                    }
                    SetProgram(50).
                }
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            set stgTimeGoGo to Time:Seconds + stgTimeGoGo.
            print "WAITING FOR ATMOSPHERIC INTERFACE":PadRight(g_termW - 33) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Atmospheric Reentry
    else if g_Program = 50
    {
        if g_Runmode = 1
        {
            if Ship:Altitude <= g_RCSDisableAlt
            {
                RCS off.
                unlock steering.
                set steerActive to false.
                SetRunmode(3).
            }
        }
        else if g_RunMode > 1
        {
            if Ship:Altitude <= fairJettAlt
            {
                SetProgram(52).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "Waiting until < {0}km ":Format(fairJettAlt) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Jettison Fairings
    else if g_Program = 52
    {
        if g_RunMode > 0
        {
            for f in fairings
            {
                local m to f:GetModule("ProceduralFairingDecoupler").
                if not DoEvent(m, "jettison fairing")
                {
                    DoAction(m, "jettison fairing", true).
                }
            }
            SetProgram(54).            
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* FAIRING JETTISON *":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Step through the predeploy altitudes
    else if g_Program = 54
    {
        if g_RunMode = 1
        {
            if Alt:Radar <= preDeployAlt
            {
                if warp > 1 set warp to 1.
                SetRunmode(2).
            }
            else
            {
                cr().
                print "PREDEPLOY: {0}":Format(Round(Alt:Radar - 1250, 2)):PadRight(g_termW - 15) at (0, cr()).
            }
        }
        else if g_Runmode = 2
        {
            if Alt:Radar <= warpZeroAlt
            {
                if warp > 0 set warp to 0.
                SetProgram(56).
            }
            else
            {
                print "DEPLOY: {0}":Format(Round(Alt:Radar - 625, 2)):PadRight(g_termW - 15) at (0, cr()).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* CHUTE DEPLOY SEQUENCE *":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Wait until touchdown
    else if g_Program = 56
    {
        if g_RunMode > 0
        {
            if Alt:Radar <= 1
            {
                SetProgram(58).            
            }
            else
            {
                cr().
                print "DISTANCE TO GROUND: {0}":Format(Round(Alt:radar, 1)):PadRight(g_termW - 15) at (0, cr()).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* WAIT FOR TOUCHDOWN *":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
    }

    // Wait until touchdown
    else if g_Program = 58
    {
        if g_RunMode > 0
        {
            cr().
            print "* RECOVERY IN {0}s *":Format(Round(g_TS - Time:Seconds, 2)):PadRight(g_termW - 15) at (0, cr()).
            if Time:Seconds >= g_TS 
            {
                SetProgram(99).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* ATTEMPT RECOVERY *":PadRight(g_termW - 15) at (0, cr()).
            set g_TS to Time:Seconds + 3.
            SetRunmode(1).
        }
    }

    // Try to recover the sucker
    else if g_Program = 99
    {
        set g_TS to 0.
        if g_RunMode > 0
        {
            cr().
            print "* RECOVERY IN {0}s *":Format(Round(g_TS - Time:Seconds, 2)):PadRight(g_termW - 15) at (0, cr()).
            TryRecoverVessel().
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            print "* ATTEMPT RECOVERY *":PadRight(g_termW - 15) at (0, cr()).
            set g_TS to Time:Seconds + 3.
            SetRunmode(1).
        }
    }
    UpdateState(true).

    if steerActive set g_Steer to steerDel:Call().
    
    print "P{0,-3}:R{1,3}  ":Format(g_Program, g_Runmode):PadRight(8) at (0, 0).

    DispDescentTelemetry(9).
}