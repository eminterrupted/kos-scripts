@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MissionTag to ParseCoreTag(core:Part:Tag).

local clampStage to Ship:ModulesNamed("LaunchClamp")[0]:Part:Stage.

local boostersActive to choose true if Ship:PartsTaggedPattern("booster\.\d*"):Length > 0 else false.
local boosterIdx     to 0.
local cb             to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag  to "".
local stagingCheckResult to 0.
local stagingDelegate to lexicon().
local stagingDelegateCheck  to { return 0.}.
local stagingDelegateAction to { return 0.}.

Breakpoint(Terminal:Input:Enter, "*** Press ENTER to launch ***").
ClearScreen.
OutMsg("Launch initiated!").
lock Throttle to 1.
wait 0.25.
LaunchCountdown().
// set g_StageEngines_Next to GetEnginesForStage(Stage:Number - 1).
// wait 0.01.
// stage.
// wait GetField(g_StageEngines_Next[0]:GetModule("ModuleEnginesRF"), "effective spool-up time", 0).

// until Stage:Number <= clampStage
// {
//     wait until Stage:Ready.
//     stage.
//     wait 1.
// }

set g_StageEngines_Current to GetEnginesForStage(Stage:Number).
set g_StageEngines_Next to GetEnginesForStage(Stage:Number - 1).

local AutoStageResult to ArmAutoStaging().
if AutoStageResult = 1
{
    Print "AutoStaging Armed with ResultCode: {0}":Format(AutoStageResult) at (2, 19).
    Print "g_StageLimit: [{0}]":Format(g_StageLimit) at (2, 20).
    set stagingDelegateCheck  to g_LoopDelegates:AutoStage["Check"].
    set stagingDelegateAction to g_LoopDelegates:AutoStage["Action"].
}

until Stage:Number = g_StageLimit
{
    // local cbCousins      to list().
    set g_StageEngines_Active to GetActiveEngines().
    // for p in g_StageEngines_Active
    // {
    //     if p:Tag:MatchesPattern("Booster.\d*")
    //     {
    if boostersActive
    {
        set curBoosterTag   to "booster.{0}":Format(boosterIdx).
        local boosterParts  to Ship:PartsTagged(curBoosterTag).
        if boosterParts:Length > 0
        {
            set cb to boosterParts[0]. // cb = CheckBooster
            // from { local i to 0.} until i = cb:SymmetryCount step { set i to i + 1. } do
            // {
            //     cbCousins:Add(cd:SymmetryPartner(i)).
            // }

            if cb:Thrust <= 0.0001
            {
                for i in Range (0, cb:SymmetryCount - 1, 1)
                {
                    cb:SymmetryPartner(i):Shutdown.
                }
                wait until Stage:Ready.
                stage.
                wait 0.01.
            
                if Ship:PartsTaggedPattern("booster.\d*"):Length < 1
                {
                    set boostersActive to false.
                }
                else
                {
                    set boosterIdx to boosterIdx + 1.
                }
            }
        }
    }

    // print stagingDelegateCheck at (2, 25).
    set stagingCheckResult to g_LoopDelegates:AutoStage:Check:Call().
    if stagingCheckResult = 1
    {
        stagingDelegateAction:Call().
    }

    // if Ship:AvailableThrust <= 0.01
    // {
    //     if Stage:Ready
    //     {
    //         Stage.
    //         wait 0.5.
    //     }
    // }

    OutInfo("Altitude: {0}m ":Format(Round(Ship:Altitude))).
    wait 0.01.
}

wait until Ship:AvailableThrust >= 1.

OutMsg("Final Burn").
until Ship:AvailableThrust <= 0.01
{
    OutInfo("Altitude: {0}m ":Format(Round(Ship:Altitude))).
    wait 0.01.
}

OutMsg("Launch script complete, performing exit actions").

// Arm any parachutes before we exit
for m in Ship:ModulesNamed("RealChuteModule")
{
    OutInfo("Arming Parachute [{0}({1})]":Format(m:part:name, m:part:uid)).
    DoEvent(m, "arm parachute").
}

// until Ship:AvailableThrust <= 0.1
// {
//     wait 0.01.
// }
// stage.
// wait 0.01.

// set g_StageEngines_Current to GetEnginesForStage(Stage:Number).
// set g_StageEngines_Next to GetEnginesForStage(Stage:Number - 1).
// local ullageEng to g_StageEngines_Next[0].
// local fuelStab to ullageEng:FuelStability.
// OutInfo("Fuel Stability: {0} ":Format(Round(fuelStab, 5)), 1).
// until ullageEng:Thrust > (ullageEng:AvailableThrust * 0.8) or fuelStab >= 0.90
// { 
//     set fuelStab to ullageEng:FuelStability.
//     OutInfo("Fuel Stability: {0} ":Format(Round(fuelStab, 5)), 1).
//     wait 0.01.
// }
// OutInfo("Ignition sequence started at FuelStability: {0}":Format(Round(fuelStab, 5))).
// wait until Stage:Ready.
// stage.
// print "~*~ (●'◡'●)  ~*~" at (2, 24).
// wait 10.















// GetField :: (Module)<Module>, (Field Name)<String>, (Default If Not Present)<any> -> (Field value or default)<any>
// Returns the value of a field on a module, provided the module has that field. 
// If the field is not present, a caller can provide a default return value in whatever type needed
global function GetField
{
    parameter _mod,
              _field,
              _def is -1.

    if _mod:HasField(_field)
    {
        return _mod:GetField(_field).
    }
    else
    {
        return _def.
    }
}


// WaitOnTermInput :: [(ContinueInput)<TerminalInput>], [(Message)<string>] -> (Continue)<bool>