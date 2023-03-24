@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).

local clampStage to Ship:ModulesNamed("LaunchClamp")[0]:Part:Stage.

local altTurn to 3500.
local boostersActive to choose true if Ship:PartsTaggedPattern("booster\.\d*"):Length > 0 else false.
local boosterIdx     to 0.
local cb             to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag  to "".
local RCSAlt         to 50000.
local RCSArmed       to Ship:ModulesNamed("ModuleRCSFX"):Length > 0 and not RCS.
local stagingCheckResult to 0.
local stagingDelegate to lexicon().
local stagingDelegateCheck  to { return 0.}.
local stagingDelegateAction to { return 0.}.
local steeringDelegate      to { return 0.}.
local tgtAlt         to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 500000.

local sounderStartTurn to 250.

wait until Ship:Unpacked.
local towerHeight to (Ship:Bounds:Size:Mag + 100).

Breakpoint(Terminal:Input:Enter, "*** Press ENTER to launch ***").
ClearScreen.
// DispTermGrid().
DispMain(ScriptPath()).
OutMsg("Launch initiated!").
lock Throttle to 1.
wait 0.25.
LaunchCountdown().
OutInfo().
OutInfo("",1).
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
    set stagingDelegateCheck  to g_LoopDelegates:AutoStage["Check"].
    set stagingDelegateAction to g_LoopDelegates:AutoStage["Action"].
}

set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("", 1).

until Alt:Radar >= towerHeight
{
    OutMsg("Liftoff! ").
    OutInfo("Altitude (Radar): {0} ({1}) ":Format(Round(Ship:Altitude), Round(Alt:Radar))).
}

set steeringDelegate to GetSteeringDelegate().

OutMsg("Vertical Ascent").
until Stage:Number <= g_StageLimit
{
    // local cbCousins      to list().
    set g_StageEngines_Active to GetActiveEngines().
    
    // for p in g_StageEngines_Active
    // {
    //     if p:Tag:MatchesPattern("Booster.\d*")
    //     {
    if boostersActive
    {
        set boosterIdx to CheckBoosterStaging().
    }

    // print stagingDelegateCheck at (2, 25).
    set stagingCheckResult to g_LoopDelegates:AutoStage:Check:Call().
    if stagingCheckResult = 1
    {
        stagingDelegateAction:Call().
    }
    if RCSArmed
    {
        if Ship:Altitude > RCSAlt { RCS on. }
        set RCSArmed to False.
    }

    // if Ship:AvailableThrust <= 0.01
    // {
    //     if Stage:Ready
    //     {
    //         Stage.
    //         wait 0.5.
    //     }
    
    steeringDelegate:Call().
    OutInfo("Altitude (Radar): {0} ({1}) ":Format(Round(Ship:Altitude), Round(Ship:Altitude - Ship:GeoPosition:TerrainHeight))).
    wait 0.01.
}

local perfObj to GetEnginesPerformanceData(GetActiveEngines()).
until perfObj:Thrust >= 0.2
{
    set perfObj to GetEnginesPerformanceData(GetActiveEngines()).
    wait 0.01.
}

OutMsg("Final Burn").
until perfObj:Thrust <= 0.1 // until Ship:AvailableThrust <= 0.01
{
    steeringDelegate:Call().
    set perfObj to GetEnginesPerformanceData(GetActiveEngines()).
    OutInfo("Altitude (Radar): {0} ({1}) ":Format(Round(Ship:Altitude), Round(Ship:Altitude - Ship:GeoPosition:TerrainHeight))).
    wait 0.01.
}

Until Ship:Altitude >= Body:ATM:Height
{
    OutMsg("Coasting out of atmosphere").
    set s_Val to Ship:Prograde.
    OutInfo("Altitude (AP ETA): {0} ({1}) ":Format(Round(Ship:Altitude), Round(ETA:apoapsis, 2))).
}

if g_StageLimitSet:Keys:Length > 0
{
    from { local i to 0.} until i = g_StageLimitSet:Keys:Length step { set i to i + 1.} do
    {
        if g_StageLimitSet[i]:s < g_StageLimit
        {
            OutMsg("Executing Event-Based Auto-Staging").
            until g_StageLimitSet[i]:C:Call()
            {
                OutInfo("AUTOSTAGE ETA: {0}  ":Format(TimeSpan(g_TS - Time:Seconds):Full)).
                set s_Val to Ship:Prograde.
                wait 0.01.
            }
            set g_StageLimit to g_StageLimitSet[i]:S.
            ArmAutoStaging().
        }
    }
}

// Arm any parachutes before we exit
for m in Ship:ModulesNamed("RealChuteModule")
{
    OutInfo("Arming Parachute [{0}({1})] ":Format(m:part:name, m:part:uid)).
    DoEvent(m, "arm parachute").
}

OutMsg("Launch script complete, performing exit actions").
OutInfo().
OutInfo("",1).
wait 1.
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

local function GetSteeringDelegate
{
    // parameter _delDependency is lexicon().
    
    local del to "".
    if g_MissionTag:Mission = "MaxAlt"
    {
        set del to { set s_Val to Heading(g_MissionTag:Params[0], g_MissionTag:Params[1], 0).}.
    }
    else if g_MissionTag:Mission = "DownRange"
    {
        set del to { if Ship:Altitude >= sounderStartTurn { local apo_err to Ship:Apoapsis / tgtAlt. set s_Val to Heading(g_MissionTag:Params[0], LaunchAngForAlt(tgtAlt, sounderStartTurn, 0, 5 + (10 * apo_err)), 0). } else { set s_Val to Heading(compass_for(Ship, Ship:Facing), 90, 0). }}.
    }
    else if g_MissionTag:Mission = "SubOrbital"
    {
        local _delDependency to InitAscentAng_Next(tgtAlt).
        set del to { if Ship:Altitude >= _delDependency:TRN_ALT_START { set s_Val to Heading(g_MissionTag:Params[0], GetAscentAng_Next(_delDependency), 0). } else { set s_Val to Heading(g_MissionTag:Params[0], 90, 0 ). }}.
    }
    else if g_MissionTag:Mission = "Orbit"
    {
        //local _delDependency to InitAscentAng_Next(tgtAlt).
        //set del to { if Ship:Altitude >= g_la_turnAltStart { set s_Val to Heading(g_MissionTag:Params[0], GetAscentAngle(g_MissionTag:Params[1]), 0). } else { set s_Val to Heading(g_MissionTag:Params[0], 90, 0). }}.
        local _delDependency to InitAscentAng_Next(tgtAlt).
        set del to { if Ship:Altitude >= _delDependency:TRN_ALT_START { set s_Val to Heading(g_MissionTag:Params[0], GetAscentAng_Next(_delDependency), 0). } else { set s_Val to Heading(g_MissionTag:Params[0], 90, 0 ). }}.
    }
    else 
    { 
        set del to {  }.
    }
    return del@.
}

local function SetSteering
{
    parameter _altTurn.

    if Ship:Altitude >= _altTurn
    {
        set s_Val to Ship:SrfPrograde - r(0, 4, 0).
    } 
    else
    {
        set s_Val to Heading(90, 88, 0).
    }
}

local function CheckBoosterStaging
{
    parameter _boosterIdx is 0.
              
    local booster_index to _boosterIdx.
    set curBoosterTag   to "booster.{0}":Format(booster_index).
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
                set booster_index to booster_index + 1.
            }
        }
    }
    return booster_index.
}











// GetField :: (Module)<Module>, (Field Name)<String>, (Default If Not Present)<any> -> (Field value or default)<any>
// Returns the value of a field on a module, provided the module has that field. 
// If the field is not present, a caller can provide a default return value in whatever type needed
// global function GetField
// {
//     parameter _mod,
//               _field,
//               _def is -1.

//     if _mod:HasField(_field)
//     {
//         return _mod:GetField(_field).
//     }
//     else
//     {
//         return _def.
//     }
// }


// WaitOnTermInput :: [(ContinueInput)<TerminalInput>], [(Message)<string>] -> (Continue)<bool>