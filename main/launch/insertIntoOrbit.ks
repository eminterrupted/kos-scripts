@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local tgtHdg to compass_for(ship, Ship:Prograde).
local waitTime to 0.

// Parse Params
if params:length > 0 
{
    set tgtHdg to ParseStringScalar(params[0], tgtHdg).
    if params:Length > 1 set waitTime to ParseStringScalar(params[1], waitTime).
}

set g_Steer to Ship:Facing.
lock steering to g_Steer.
set g_Throt to 0.

set g_ShipEngines to GetShipEnginesSpecs(Ship).
set g_NextEngines to GetNextEngines(Ship, "1000").

local nextStage to Stage:Number.

if g_NextEngines:Length > 0
{
    set nextStage to g_NextEngines[0]:Stage.
    if waitTime = 0 
    {
        if g_ShipEngines:IGNSTG:HasKey(nextStage)
        {
            set waitTime to g_ShipEngines:IGNSTG[nextStage]:STGBURNTIME / 2.
            print "NEXTENGS[0]: {0}":Format(g_NextEngines:Length) at (2, 28).
            print "STGBURNTIME: {0}":Format(g_ShipEngines:IGNSTG[nextStage]:STGBURNTIME) at (2, 29).
            print "Wait time updated: {0}":Format(waitTime) at (2, 30).
        }
    }
}

local line to 5.

until g_Program > 199 or g_Abort
{
    set g_Line to line.
    if g_Program < 100 
    {
        SetProgram(100).
    }
    else if g_Program = 100
    {
        if g_RunMode > 0
        {
            if ETA:Apoapsis <= waitTime
            {
                clr(cr()).
                SetProgram(110).
            }
            else
            {
                print "BURN ETA: T{0}   ":Format(Round(waitTime - ETA:Apoapsis, 2)) at (0, cr()).
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
            print "ORBITAL INSERTION: COAST":PadRight(g_termW - 24) at (0, g_Line).
            SetRunmode(1).
        }
        
    }
    else if g_Program = 110
    {
        if g_RunMode > 0
        {
            ArmAutoStaging(g_StageLimit).
            set g_Throt to 1.
            lock throttle to g_Throt.
            SetProgram(120).
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
            print "ORBITAL INSERTION: IGNITION":PadRight(g_termW - 27) at (0, g_Line).
            SetRunmode(1).
        }
    }
    else if g_Program = 120
    {
        if g_RunMode = 1
        {
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).
            if Stage:Number <= g_StageLimit and Ship:AvailableThrust <= 0.01
            {
                set g_Throt to 0.
                SetProgram(130).
            }
            else
            {
                print "BURNTIME REMAINING: {0}s ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)) at (0, cr()).
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
            print "ORBITAL INSERTION: BURN":PadRight(g_termW - 23) at (0, g_Line).
            SetRunmode(1).
        }
    }
    else if g_Program = 130
    {
        if g_RunMode = 1
        {
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).
            if g_ActiveEngines_PerfData:Thrust <= 0.001
            {
                unlock steering.
                SetProgram(200).
            }
            else
            {
                clr(cr()).
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
            print "ORBITAL INSERTION: COMPLETE":PadRight(g_termW - 27) at (0, g_Line).
            SetRunmode(1).
        }
    }
    

    set g_Steer to choose heading(tgtHdg, 0, 0):Vector if g_Spin_Active else heading(tgtHdg, 0, 0).
    UpdateState().


    if g_HS_Armed 
    {
        print "HotStaging: Armed" at (0, cr()).
        // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
        local btrem to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else GetActiveBurnTimeRemaining(g_ActiveEngines).
        if g_HS_Check:Call(btrem)
        {
            g_HS_Act:Call().
        }
    }
    if g_AS_Armed 
    {
        print "Autostaging: Armed" at (0, cr()).
        if g_AS_Check:Call()
        {
            g_AS_Act:Call().
        }
    }
    if g_Spin_Armed
    {
        print "SpinStabilization: Armed" at (0, cr()).
        if g_Spin_Check:Call()
        {
            g_Spin_Act:Call().
        }
    }
}

ClearScreen.
print "Hopefully you are in orbit.".
print "If so, thank you for flying with Aurora, and enjoy space.".
print " ".
print "If not, well, hold on to your butts because this is gonna".
print "get real, real quick.".