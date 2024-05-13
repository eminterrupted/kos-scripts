@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/abort").

// Declare Variables
local LESObj to lex().

// Parse Params
if _params:length > 0 
{
  set LESObj to _params[0].
}
else
{
    set LESObj to GetAbortSystem().
}

SetProgram(900).
SetRunmode(0).

local accumSteerDeflect to 0.
local steerDeflect to 0.25.

local settleTS to 0.

set g_Throt to 0.
lock throttle to g_Throt.
local steerDel to { return Ship:Facing.}.
set g_Steer to steerDel:Call().
lock steering to g_Steer.

local abortDispDel to {
    set g_Line to 10.
    if Floor(Time:Seconds, 2) = 0
    {
        OutMsg("     *** ABORT ***     ", g_Line).
    }
    else
    {
        clr(g_Line).
    }
    cr().
    cr().
    DispDescentTelemetry().
}.

until g_Program < 0
{
    abortDispDel:Call().
    cr().

    if g_Program = 900
    {
        if g_Runmode = 1
        {
            set g_Throt to 1.
            for eng in LESObj:ENG
            {
                eng:Activate.
            }
            SetProgram(902).
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
            OutMsg("ABORT ENGINE IGNITION").
            SetRunmode(1).
        }
    }

    else if g_Program = 902
    {
        if g_Runmode = 1
        {
            for dc in LESObj:DC0
            {
                if dc:HasModule("ModuleDecouple")
                {
                    DoEvent(dc:GetModule("ModuleDecouple"), "decouple").
                }
            }
            SetProgram(905).
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
            OutMsg("DC0").
            SetRunmode(1).
        }
    }

    else if g_Program = 905
    {
        if g_Runmode = 1
        {
            local curDir to Ship:Facing.
            set steerDel to { return curDir + r(0, accumSteerDeflect, 0).}.
            SetProgram(2).
        }
        else if g_Runmode = 2
        {
            SetProgram(910).
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
            OutMsg("BLOCK DISP").
            SetRunmode(1).
        }
    }

    else if g_Program = 910
    {
        set accumSteerDeflect to accumSteerDeflect + steerDeflect.
        if g_Runmode = 1
        {
            set g_TS_0 to Time:Seconds + 5.
            SetProgram(913).
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
            OutInfo("WAIT CALC").
            SetRunmode(1).
        }
    }

    else if g_Program = 913
    {
        set accumSteerDeflect to accumSteerDeflect + steerDeflect.
        if g_Runmode = 1
        {
            if Ship:AvailableThrust > 0 and Time:Seconds > g_TS_0 
            {
                set g_TS_0 to Time:Seconds + 3.
                SetProgram(915).
            }
            else
            {
                local btRem to GetActiveBurnTimeRemaining().
                local progETA to Max(g_TS_0, btRem).
                OutInfo("ETA: {0}":Format(Round(progETA, 2))).
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
            OutMsg("WAIT: AVAIL THRUST STAGE").
            SetRunmode(1).
        }
    }

    else if g_Program = 915
    {
        set accumSteerDeflect to accumSteerDeflect + steerDeflect.
        if g_Runmode = 1
        {
            if Ship:VerticalSpeed < 0 and Time:Seconds > g_TS_0
            {
                SetProgram(917).
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
            OutMsg("WAIT: VERTSPD").
            SetRunmode(1).
        }
    }

    else if g_Program = 917
    {
        if g_Runmode = 1
        {
            for dc in LESObj:DC1
            {
                local m to choose dc:GetModule("ModuleDecouple") if dc:HasModule("ModuleDecouple") else choose dc:GetModule("ProceduralFairingDecoupler") if dc:HasModule("ProceduralFairingDecoupler") else "NUL".
                if m:IsType("PartModule") DoEvent(m, "Decouple").
            }
            SetProgram(919).
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
            OutMsg("DC1").
            SetRunmode(1).
        }
    }

    // Jettison Fairings
    else if g_Program = 919
    {
        if g_RunMode > 0
        {
            for m in Ship:ModulesNamed("ProceduralFairingDecoupler")
            {
                if not DoEvent(m, "jettison fairing")
                {
                    DoAction(m, "jettison fairing", true).
                }
            }
            lights on.
            SetProgram(921).            
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
            OutMsg("* FAIRING JETTISON *":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
    }

    // Step through the predeploy altitudes
    else if g_Program = 921
    {
        if g_RunMode = 1
        {
            if Alt:Radar <= 1250
            {
                if warp > 1 set warp to 1.
                SetRunmode(2).
            }
            else
            {
                cr().
                OutMsg("PREDEPLOY: {0}":Format(Round(Alt:Radar - 1250, 2)):PadRight(g_termW - 15), cr()).
            }
        }
        else if g_Runmode = 2
        {
            if Alt:Radar <= 25
            {
                if warp > 0 set warp to 0.
                SetProgram(923).
            }
            else
            {
                OutMsg("DEPLOY: {0}":Format(Round(Alt:Radar - 625, 2)):PadRight(g_termW - 15), cr()).
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
            OutMsg("* CHUTE DEPLOY SEQUENCE *":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
    }

    // Wait until touchdown
    else if g_Program = 923
    {
        if g_RunMode = 1
        {
            for m in Ship:ModulesNamed("ModuleAnimateGeneric")
            {
                if DoAction(m, "toggle landing bag") = 1
                {
                    OutInfo("LANDING BAG DEPLOY", cr()).
                }
            }
            SetRunmode(2).
        }
        else if g_RunMode = 2
        {
            if Alt:Radar <= 1
            {
                SetProgram(925).            
            }
            else
            {
                cr().
                OutInfo("DISTANCE TO GROUND: {0}":Format(Round(Alt:radar, 1)):PadRight(g_termW - 15), cr()).
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
            OutMsg("* WAIT FOR TOUCHDOWN *":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
    }

    // Wait until touchdown
    else if g_Program = 925
    {
        if g_RunMode > 0
        {
            cr().
            OutInfo("* RECOVERY IN {0}s *":Format(Round(settleTS - Time:Seconds, 2)):PadRight(g_termW - 15), cr()).
            if Time:Seconds >= settleTS 
            {
                SetProgram(927).
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
            OutMsg("* ATTEMPT RECOVERY *":PadRight(g_termW - 15), cr()).
            set settleTS to Time:Seconds + 3.
            SetRunmode(1).
        }
    }

    // Try to recover the sucker
    else if g_Program = 927
    {
        set settleTS to 0.
        if g_RunMode > 0
        {
            cr().
            OutInfo("* RECOVERY IN {0}s *":Format(Round(settleTS - Time:Seconds, 2)):PadRight(g_termW - 15), cr()).
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
            OutMsg("* ATTEMPT RECOVERY *":PadRight(g_termW - 15), cr()).
            set settleTS to Time:Seconds + 3.
            SetRunmode(1).
        }
    }
    set g_Steer to steerDel:Call().
    
    OutStr("P{0,-3}:R{1,3}:SL{2,3}  ":Format(g_Program, g_Runmode, g_StageLimit):PadRight(8), 0).
    
}