@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/reentry.ks").
RunOncePath("0:/lib/sci.ks").
RunOncePath("0:/lib/dvCalc.ks").
RunOncePath("0:/lib/mnv.ks").


// Declare Variables
local deorbitNode   to Node(0, 0, 0, 0).
local retroBurnTS        to Time:Seconds + ETA:Apoapsis.
local fairings      to list().
local fairJettAlt   to 10000.
local preDeployAlt  to 2000.
local retroBurn     to false.
local settleTS      to 0.
local stgTimeGoGo   to 5.
local suppressRecovery to false.
local tgtReentryAlt to 140000.
local warpZeroAlt   to 25.

// Parse Params
if _params:length > 0 
{
  set tgtReentryAlt to ParseStringScalar(_params[0], tgtReentryAlt).
  if _params:Length > 1 set suppressRecovery to _params[1].
  if _params:Length > 2 set retroBurn to _params[2].
  if _params:Length > 3 set retroBurnTS to ParseStringScalar(_params[3], retroBurnTS).
}

local tgtReentryAltWarpStop to tgtReentryAlt * 1.2.

set g_Line to 4.
local steerDel to { return Ship:SrfRetrograde.}.
set g_Steer to steerDel:Call().

SAS off.
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
if g_MissionPlan:HasKey("S")
{
    if g_MissionPlan:S:Length > 0
    {
        SetStageLimit(g_MissionPlan:S[g_MissionPlan:S:Length - 1]:ToNumber(2)).
    }
    else
    {
        SetStageLimit(2).
    }
}

until g_Program > 199 or g_Abort
{
    GetTermChar().
    
    set g_Line to 4.

    if g_Program < 10
    {
        SetProgram(10).
    }

    else if g_Program = 10
    {
        if g_RunMode = 1
        {
            set g_ShipEngines to GetShipEnginesSpecs().
            if HasNode 
            {
                SetRunmode(2).
            }
            else if retroBurn
            {
                SetRunmode(3).
            }
            else
            {
                SetRunmode(4).
            }
        }
        else if g_Runmode = 2
        {
            SetProgram(22).
        }
        else if g_Runmode = 3
        {
            SetProgram(24).
        }
        else if g_Runmode = 4
        {
            SetProgram(40).
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
            OutMsg("CHECKING MANUEVER", cr()).
            SetRunmode(1).
        }
        set g_Steer to steerDel:Call().
    }

    // Use ExecNodeBurn to deorbit
    else if g_Program = 22
    {
        if g_RunMode = 1
        {
            // This is a fake node, bail
            if deorbitNode:DeltaV:Mag = 0
            {
                SetProgram(40). 
            }

            set steerDel to { return deorbitNode:DeltaV.}.
            set settleTS to Time:Seconds + 10.
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {
            if Time:Seconds >= settleTS and VAng(Ship:Facing, deorbitNode:DeltaV) <= 0.25
            {
                set settleTS to 0.
                SetRunmode(4).
            }
        }
        else if g_Runmode = 4
        {
            if Time:Seconds >= retroBurnTS - 15
            {
                if warp > 0 set warp to 0.
                wait until Kuniverse:TimeWarp:IsSettled.
                SetRunmode(6).
            }
            else
            {
                if g_TermChar = "w"
                {
                    WarpTo(retroBurnTS - 15).
                }
            }
        }
        else if g_Runmode = 6
        {
            ExecNodeBurn(deorbitNode).
            SetProgram(27).
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
            set deorbitNode to choose NextNode if HasNode else deorbitNode.
            set retroBurnTS to Round(NextNode:Time, 2).
            OutMsg("EXEC DEORBIT NODE", cr()).
            SetRunmode(1).
        }
        OutMsg("TIME TO NODE: [T{0}] ":Format(Time:Seconds - retroBurnTS), cr()).
        set g_Steer to steerDel:Call().
    }

    // Wait until retroBurnTS
    else if g_Program = 24
    {
        if g_RunMode = 1
        {
            set steerDel to { return Ship:Retrograde.}.
            set settleTS to Time:Seconds + 10.
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {
            if Time:Seconds >= settleTS
            {
                set settleTS to 0.
                SetRunmode(4).
            }
        }
        else if g_Runmode = 4
        {
            if Time:Seconds >= retroBurnTS - 15
            {
                // clr(cr()).
                if warp > 0 set warp to 0.
                wait until Kuniverse:TimeWarp:IsSettled.
                SetRunmode(6).
            }
            else
            {
                if g_TermChar = "w"
                {
                    WarpTo(retroBurnTS - 15).
                }
            }
        }
        else if g_Runmode = 6
        {
            SetProgram(27).
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
            OutMsg("WAIT FOR REENTRY BURN", cr()).
            SetRunmode(1).
        }
        OutMsg("TIME TO REENTRY BURN: [T{0}] ":Format(Time:Seconds - retroBurnTS), cr()).
        set g_Steer to steerDel:Call().
    }

    // Execute Retro Burn
    else if g_Program = 27
    {
        if g_RunMode = 1
        {
            if Stage:Number > g_StageLimit
            {
                wait 0.25.
                SafeStageWithUllage().
                wait 0.5.
                set g_ActiveEngines to GetActiveEngines().
                if g_ActiveEngines:Length > 0
                {
                    SetRunmode(2).
                }
            }
            else
            {
                SetRunmode(4).
            }
        }
        else if g_Runmode = 2
        {
            local btRem to GetActiveBurnTimeRemaining(g_ActiveEngines).
            if btRem <= 0.001 or Ship:AvailableThrust = 0
            {
                SetRunmode(1).
            }
            else
            {
                OutMsg("BURN TIME REMAINING: [T{0}] ":Format(Round(btRem, 2)), cr()).
            }
        }
        else if g_Runmode = 4
        {
            SetProgram(40).
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
            OutMsg("REENTRY BURN", cr()).
            SetRunmode(1).
        }
    }
    
    // Position to Surface retrograde
    else if g_Program = 40
    {
        if g_RunMode = 1
        {
            set steerDel to { return Ship:SrfRetrograde. }.
            set settleTS to Time:Seconds + 3.
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {
            if Time:Seconds >= settleTS and VAng(Ship:Facing:Vector , Ship:SrfRetrograde:Vector) <= 0.25
            {
                set settleTS to 0.
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
            OutMsg("ALIGN TO SRF RETRO", cr()).
            SetRunmode(1).
        }
    }

    // Wait for reentry alt
    else if g_Program = 42
    {
        // First check to see if we are warping to set the appropriate runmode
        if Warp > 0
        {
            SetRunmode(2).
        }
        else
        {
            SetRunmode(1).
        }

        if g_RunMode = 1
        {
            if Time:Seconds >= settleTS
            {
                set settleTS to 0.
                SetRunmode(4).
            }
        }
        else if g_Runmode = 2
        {
            if Ship:Altitude <= tgtReentryAltWarpStop
            {
                Set Warp to 0.
                SetRunmode(3).
                clr(cr()).
            }
            else
            {
                OutInfo("WARP ACTIVE: [{0}]":Format(Warp)).
            }
        }
        else if g_Runmode = 3
        {
            if Ship:Settled
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
            OutMsg("WAIT FOR REENTRY BURN", cr()).
            SetRunmode(1).
        }

        if g_TermChar = "w"
        {
            WarpTo(retroBurnTS - 15).
        }

        OutMsg("TIME TO REENTRY BURN: [T{0}] ":Format(Time:Seconds - retroBurnTS), cr()).
        set g_Steer to steerDel:Call().
    }

    // Arm Chutes
    else if g_Program = 46
    {
        if g_RunMode = 1
        {
            ArmParachutes().
            SetRunmode(3).
        }
        else if g_RunMode = 3
        {
            OutMsg("* CHUTE(S) ARMED *":PadRight(g_termW - 18), cr()).
            SetProgram(47).            
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
            OutMsg("* ARMING CHUTE(S) *":PadRight(g_termW - 20), cr()).
            SetRunmode(1).
        }
    }

    // Collect Sci
    else if g_Program = 47
    {
        if g_RunMode > 0
        {
            TransferSciData(core:part).
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
            OutMsg("* COLLECTING SCIENCE *":PadRight(g_termW - 20), cr()).
            SetRunmode(1).
        }
    }

    // Wait for reentry alt
    else if g_Program = 48
    {
        if g_Runmode = 1
        {
            if Ship:Altitude <= tgtReentryAlt
            {
                SetProgram(49).
            }
            else
            {
                local timeToReentryAlt to Round((Ship:Altitude - tgtReentryAlt) / (Ship:VerticalSpeed + (Constant:g * Ship:Body:Mass) / (Ship:Altitude + Ship:Body:Radius)^2), 2).
                OutMsg("ETA TO ATMOSPHERIC INTERFACE: {0} ":Format(timeToReentryAlt), cr()).
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
            OutMsg("WAITING FOR ATMOSPHERIC INTERFACE":PadRight(g_termW - 33), cr()).
            SetRunmode(1).
        }
    }

// Stage at reentry alt
    else if g_Program = 49
    {
        if g_Runmode = 1
        {
            if Time:Seconds > stgTimeGoGo
            {
                SetRunmode(3).
            }
            else
            {
                clr(cr()).
                OutMsg("STAGING: {0} ":Format(Time:Seconds - stgTimeGoGo), cr()).
            }
        }
        else if g_Runmode = 3
        {
            clr(cr()).
            OutMsg("STAGING ", cr()).
            if Stage:Number > 1
            {
                set g_ActiveEngines to GetActiveEngines().
                local thr to 0.
                for eng in g_ActiveEngines
                {
                    set thr to thr + eng:Thrust.
                }
                if thr = 0
                {
                    if Stage:Ready 
                    {
                        stage.
                        wait 0.1.
                    }
                }
            }
            else
            {
                SetProgram(50).
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
            OutMsg("WAITING FOR ATMOSPHERIC INTERFACE":PadRight(g_termW - 33), cr()).
            SetRunmode(1).
        }
        OutMsg("ETA TO ATMOSPHERIC INTERFACE: {0} ":Format(-1), cr()).
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
        else if g_RunMode = 3
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
            OutMsg("Waiting until < {0}km ":Format(fairJettAlt), cr()).
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
            lights on.
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
            OutMsg("* FAIRING JETTISON *":PadRight(g_termW - 15), cr()).
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
                OutMsg("PREDEPLOY: {0}":Format(Round(Alt:Radar - 1250, 2)):PadRight(g_termW - 15), cr()).
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
    else if g_Program = 56
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
                SetProgram(58).            
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
    else if g_Program = 58
    {
        if g_RunMode > 0
        {
            cr().
            OutInfo("* RECOVERY IN {0}s *":Format(Round(settleTS - Time:Seconds, 2)):PadRight(g_termW - 15), cr()).
            if Time:Seconds >= settleTS 
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
            OutMsg("* ATTEMPT RECOVERY *":PadRight(g_termW - 15), cr()).
            set settleTS to choose Time:Seconds + 3 if Ship:Crew:Length = 0 else 0.25.
            SetRunmode(1).
        }
    }

    // Try to recover the sucker
    else if g_Program = 99
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
    UpdateState(true).

    if steerActive set g_Steer to steerDel:Call().
    
    OutStr("P{0,-3}:R{1,3}  ":Format(g_Program, g_Runmode):PadRight(8), 0).

    DispDescentTelemetry(9).
}