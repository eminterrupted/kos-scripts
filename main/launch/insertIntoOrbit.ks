@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/launch").
RunOncePath("0:/kslib/lib_l_az_calc").

// Declare Variables
local burnLeadTime      to 10.
local burnTS            to 0.
local stageBurnTimes    to lex().
local tgtPe             to Ship:Apoapsis.
local tgtHdg            to compass_for(ship, Ship:Prograde).
local totalBurnTime     to 0.
local waitTime          to 0.
local warpFlag          to false.
local ullageTime        to 10.
local ullageTS          to 0.

// Parse Params
if _params:length > 0 
{
    // set tgtHdg to ParseStringScalar(params[0], tgtHdg).
    // if params:Length > 1 set waitTime to ParseStringScalar(params[1], waitTime).
    set tgtPe to ParseStringScalar(_params[0], tgtPe).
}

local steerDel to {  if g_Spin_Active { return heading(tgtHdg, 0, 0):Vector.} else { return heading(tgtHdg, 0, 0).}}.

if g_AzData:Length > 0
{
    set steerDel to {  if g_Spin_Active { return heading(l_az_calc(g_AzData), 0, 0). } else { return heading(l_az_calc(g_AzData), 0, 0).}}.
}
set g_Steer to Ship:Facing.
lock steering to g_Steer.
set g_Throt to 0.

set g_ShipEngines to GetShipEnginesSpecs(Ship).
set g_NextEngines to GetNextEngines("1000").


set stageBurnTimes  to GetStageBurnTimes(Stage:Number - 1, 0).
set totalBurnTime   to stageBurnTimes:TOTAL.
set waitTime        to totalBurnTime / 2.
set burnTS          to Time:Seconds + ETA:Apoapsis - (waitTime * 1.1).
set ullageTS        to burnTS - ullageTime.

OutInfo("TOTALBURNTIME: {0} ":Format(totalBurnTime), 4).
local line to 5.

RCS on.

until g_Program > 199 or g_Abort
{
    GetTermChar().

    set g_Line to line.
    if g_Program < 100 
    {
        SetProgram(100).
    }
    else if g_Program = 100
    {
        if g_RunMode > 0
        {
            if Time:Seconds >= ullageTS
            {
                clr(cr()).
                SetProgram(110).
            }
            else 
            {
                SetProgram(104).
            }
            
            OutInfo("BURN ETA: T{0}   ":Format(Round(waitTime - ETA:Apoapsis, 2)), cr()).
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
            OutInfo("ORBITAL INSERTION: COAST":PadRight(g_termW - 24), g_Line).
            SetRunmode(1).
        }
        
    }
    else if g_Program = 104
    {
        if g_Runmode = 1
        {
            if Time:Seconds >= ullageTS
            {
                SetRunmode(2).
            }
            else
            {
            }
        }
        else if g_Runmode = 2
        {
            if g_ShipEngines:IGNSTG[g_NextEngines[0]:Stage]:ULLAGE
            {
                RCS On.
                set Ship:Control:Fore to 1.
            }
            SetRunmode(4).
        }
        else if g_Runmode = 4
        {
            if Time:Seconds >= burnTS
            {
                SetProgram(110).
            }
            else
            {
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
            OutInfo("ORBITAL INSERTION: WAIT":PadRight(g_termW - 24), g_Line).
            SetRunmode(1).
        }
        OutInfo("BURN ETA: T{0}   ":Format(Round(BurnTS - Time:Seconds, 2)), cr()).
    }
    else if g_Program = 110
    {
        if g_RunMode = 1
        {
            ArmAutoStaging(g_StageLimit).
            set g_Throt to 1.
            lock throttle to g_Throt.
            SetRunmode(2).
        }
        else if g_RunMode = 2
        {
            set Ship:Control:Fore to 0.
            SetRunmode(4).
        }
        else if g_Runmode = 4
        {
            ArmSpinStabilization().
            SetRunmode(8).
        }
        else if g_Runmode = 8
        {
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
            OutInfo("ORBITAL INSERTION: IGNITION":PadRight(g_termW - 27), g_Line).
            SetRunmode(1).
        }
    }
    else if g_Program = 120
    {
        if g_RunMode = 1
        {
            set g_ActiveEngines to GetActiveEngines().
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {   
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, "11100000").
            if Ship:Periapsis >= tgtPe
            {
                set g_Throt to 0.
                OutInfo("PE REACHED / ENGINE CUTOUT":PadRight(g_termW - 26), cr()).
                SetProgram(130).
            }
            else if Stage:Number <= g_StageLimit and Ship:AvailableThrust <= 0.01
            {
                set g_Throt to 0.
                OutInfo("ENGINE CUTOUT":PadRight(g_termW - 13), cr()).
                SetProgram(130).
            }
            else
            {
                OutInfo("BURNTIME REMAINING: {0}s ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)), cr()).
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
            OutInfo("ORBITAL INSERTION: BURN":PadRight(g_termW - 23), g_Line).
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
                clr(cr()).
                SetProgram(200).
            }
            else
            {
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
            OutInfo("ORBITAL INSERTION: COMPLETE":PadRight(g_termW - 27), g_Line).
            SetRunmode(1).
        }
    }
    
    set g_Steer to steerDel:Call().
    UpdateState().

    local btRem to GetActiveBurnTimeRemaining(GetActiveEngines(Ship, False)).
    if g_HS_Armed 
    {
        print "HotStaging [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
        // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
        // local btrem to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else GetActiveBurnTimeRemaining(g_ActiveEngines).
        if g_HS_Check:Call(btrem)
        {
            g_HS_Action:Call().
        }
    }
    if g_AS_Armed 
    {
        OutMsg("Autostaging: Armed", cr()).
        if g_AS_Check:Call()
        {
            g_AS_Action:Call().
        }
    }
    if g_Spin_Armed
    {
        print "SpinStabilization [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
        if g_Spin_Check:Call(btrem)
        {
            g_Spin_Action:Call().
        }
    }
    if not HomeConnection:IsConnected()
    {
        if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
        {
            for m in Ship:ModulesNamed("ModuleDeployableAntenna")
            {
                DoEvent(m, "extend antenna").
            }
        }
    }

    OutStr("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20), 0).
}

ClearScreen.
print "Hopefully you are in orbit.".
print "If so, thank you for flying with Aurora, and enjoy space.".
print " ".
print "If not, well, hold on to your butts because this is gonna".
print "get real, real quick.".