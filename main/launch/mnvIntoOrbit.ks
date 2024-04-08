@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/launch").
RunOncePath("0:/lib/mnv").
RunOncePath("0:/kslib/lib_l_az_calc").


// Declare Variables
local tgtPe to Ship:Apoapsis.
local tgtHdg to compass_for(ship, Ship:Prograde).
local totBurnTime to 0.
local waitTime to 0.

// Parse Params
if params:length > 0 
{
    // set tgtHdg to ParseStringScalar(params[0], tgtHdg).
    // if params:Length > 1 set waitTime to ParseStringScalar(params[1], waitTime).
    set tgtPe to ParseStringScalar(params[0], tgtPe).
}

local steerDel to {  if g_Spin_Active { return heading(tgtHdg, 0, 0):Vector.} else { return heading(tgtHdg, 0, 0).}}.

if g_AzData:Length > 0
{
    set steerDel to {  if g_Spin_Active { return heading(l_az_calc(g_AzData), 0, 0). } else { return heading(l_az_calc(g_AzData), 0, 0).}}.
}
set g_Steer to Ship:Facing.
lock steering to g_Steer.
set g_Throt to 0.


// Remove any existing node se we can recalculate
if HasNode remove NextNode.
local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, Ship:Apoapsis, Ship:Apoapsis, "pe").

local circNode to node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).
add circNode.


ExecNodeBurn(circNode).




// set g_ShipEngines to GetShipEnginesSpecs(Ship).
// set g_NextEngines to GetNextEngines("1000").

// from { local i to Stage:Number - 1.} until i < g_StageLimit step { set i to i - 1.} do 
// {
//     // if g_NextEngines:Length > 0
//     local stgEngsBT to 0.
//     if g_ShipEngines:IGNSTG:HasKey(i)
//     {
//         // if waitTime = 0 
//         // {
//             if g_ShipEngines:IGNSTG:HasKey(i)
//             {
//                 set stgEngsBT to g_ShipEngines:IGNSTG[i]:STGBURNTIME.
//                 set waitTime to waitTime + (stgEngsBT / 2).
//                 OutInfo("STGENGS[{0}]: {1}":Format(i, g_NextEngines:Length), 28).
//                 OutInfo("STGBURNTIME: {0}":Format(stgEngsBT), 29).
//             }
//         // }
//     }
    
//     OutInfo("TOTBURNTIME: {0} ":Format(totBurnTime + stgEngsBT), 30).
// }

// // Adjust wait time slightly
// set waitTime to waitTime * 1.625.
// OutMsg("WAITTIME   : {0} ":Format(waitTime), 31).

// local line to 5.

// RCS on.

// until g_Program > 199 or g_Abort
// {
//     set g_Line to line.
//     if g_Program < 100 
//     {
//         SetProgram(100).
//     }
//     else if g_Program = 100
//     {
//         if g_RunMode > 0
//         {
//             if ETA:Apoapsis <= waitTime
//             {
//                 clr(cr()).
//                 SetProgram(110).
//             }
//             else if g_Runmode = 1
//             {
//                 if ETA:Apoapsis <= (waitTime + 10)
//                 {
//                     if g_ShipEngines:IGNSTG[g_NextEngines[0]:Stage]:ULLAGE
//                     {
//                         SetRunmode(3).
//                         RCS On.
//                         set Ship:Control:Fore to 1.
//                     }
//                     else
//                     {
//                         SetRunmode(2).
//                     }
//                 }
//             }
            
//             OutInfo("BURN ETA: T{0}   ":Format(Round(waitTime - ETA:Apoapsis, 2)), cr()).
//         }
//         else if g_Runmode < 0
//         {
//             if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
//             {
//                 set g_Abort     to True.
//                 set g_AbortCode to g_Program.
//             }
//         }
//         else
//         {
//             OutInfo("ORBITAL INSERTION: COAST":PadRight(g_termW - 24), g_Line).
//             SetRunmode(1).
//         }
        
//     }
//     else if g_Program = 110
//     {
//         if g_RunMode = 1
//         {
//             ArmAutoStaging(g_StageLimit).
//             set g_Throt to 1.
//             lock throttle to g_Throt.
//             SetRunmode(2).
//         }
//         else if g_RunMode = 2
//         {
//             set Ship:Control:Fore to 0.
//             SetProgram(120).
//         }
//         else if g_Runmode < 0
//         {
//             if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
//             {
//                 set g_Abort     to True.
//                 set g_AbortCode to g_Program.
//             }
//         }
//         else
//         {
//             OutInfo("ORBITAL INSERTION: IGNITION":PadRight(g_termW - 27), g_Line).
//             SetRunmode(1).
//         }
//     }
//     else if g_Program = 120
//     {
//         if g_RunMode = 1
//         {
//             set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).
//             if Ship:Periapsis >= tgtPe
//             {
//                 set g_Throt to 0.
//                 OutInfo("PE REACHED / ENGINE CUTOUT":PadRight(g_termW - 26), cr()).
//                 SetProgram(130).
//             }
//             else if Stage:Number <= g_StageLimit and Ship:AvailableThrust <= 0.01
//             {
//                 set g_Throt to 0.
//                 OutInfo("ENGINE CUTOUT":PadRight(g_termW - 13), cr()).
//                 SetProgram(130).
//             }
//             else
//             {
//                 OutInfo("BURNTIME REMAINING: {0}s ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)), cr()).
//             } 
//         }
//         else if g_Runmode < 0
//         {
//             if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
//             {
//                 set g_Abort     to True.
//                 set g_AbortCode to g_Program.
//             }
//         }
//         else
//         {
//             OutInfo("ORBITAL INSERTION: BURN":PadRight(g_termW - 23), g_Line).
//             SetRunmode(1).
//         }
//     }
//     else if g_Program = 130
//     {
//         if g_RunMode = 1
//         {
//             set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).
//             if g_ActiveEngines_PerfData:Thrust <= 0.001
//             {
//                 unlock steering.
//                 clr(cr()).
//                 SetProgram(200).
//             }
//             else
//             {
//             }
            
//         }
//         else if g_Runmode < 0
//         {
//             if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
//             {
//                 set g_Abort     to True.
//                 set g_AbortCode to g_Program.
//             }
//         }
//         else
//         {
//             OutInfo("ORBITAL INSERTION: COMPLETE":PadRight(g_termW - 27), g_Line).
//             SetRunmode(1).
//         }
//     }
    
//     set g_Steer to steerDel:Call().
//     UpdateState().


//     if g_HS_Armed 
//     {
//         OutMsg("HotStaging: Armed", cr()).
//         // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
//         local btrem to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else GetActiveBurnTimeRemaining(g_ActiveEngines).
//         if g_HS_Check:Call(btrem)
//         {
//             g_HS_Action:Call().
//         }
//     }
//     if g_AS_Armed 
//     {
//         OutMsg("Autostaging: Armed", cr()).
//         if g_AS_Check:Call()
//         {
//             g_AS_Action:Call().
//         }
//     }
//     if g_Spin_Armed
//     {
//         OutMsg("SpinStabilization: Armed", cr()).
//         if g_Spin_Check:Call()
//         {
//             g_Spin_Action:Call().
//         }
//     }
//     if not HomeConnection:IsConnected()
//     {
//         if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
//         {
//             for m in Ship:ModulesNamed("ModuleDeployableAntenna")
//             {
//                 DoEvent(m, "extend antenna").
//             }
//         }
//     }

//     OutStr("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20), 0).
// }

ClearScreen.
print "Hopefully you are in orbit.".
print "If so, thank you for flying with Aurora, and enjoy space.".
print " ".
print "If not, well, hold on to your butts because this is gonna".
print "get real, real quick.".