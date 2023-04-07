@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).

local clampStage to Ship:ModulesNamed("LaunchClamp")[0]:Part:Stage.

local altTurn to 3500.
local boostersArmed  to choose true if Ship:PartsTaggedPattern("booster\.\d*"):Length > 0 else false.
local boostersArmed  to choose true if Ship:PartsTaggedPattern("booster\.\d*"):Length > 0 else false.
local boosterIdx     to 0.
local cb             to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag  to "".
local RCSAlt         to 50000.
local RCSArmed       to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local RCSArmed       to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local stagingCheckResult to 0.
local stagingDelegate to lexicon().
local stagingDelegateCheck  to { return 0.}.
local stagingDelegateAction to { return 0.}.
local steeringDelegate      to { return 0.}.
local tgtAlt         to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 500000.
local ThrustThresh   to 0.
local ThrustThresh   to 0.

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

ArmBoosterStaging().

set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("", 1).

OutMsg("Liftoff! ").
OutMsg("Liftoff! ").
until Alt:Radar >= towerHeight
{
    if g_BoostersArmed { CheckBoosterStageCondition().}
    DispLaunchTelemetry().
    // DispEngineTelemetry().
}

OutInfo("ArmFairingJettison() result: {0}":Format(ArmFairingJettison())).
set steeringDelegate to GetSteeringDelegate().

OutMsg("Vertical Ascent").
until Stage:Number <= g_StageLimit
{
    set g_StageEngines_Active to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_BoostersArmed { CheckBoosterStageCondition().}
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
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecLoopEventDelegates().
    }

    steeringDelegate:Call().
    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}

set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
until g_ActiveEngines_Data:Thrust >= 0.2
{
    if g_BoostersArmed { CheckBoosterStageCondition().}
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}

OutMsg("Final Burn").
until g_ActiveEngines_Data:Thrust <= 0.1 // until Ship:AvailableThrust <= 0.01
{
    steeringDelegate:Call().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}
ClearDispBlock("ENGINE_TELEMETRY").

OutMsg("Coasting out of atmosphere").
OutMsg("Coasting out of atmosphere").
Until Ship:Altitude >= Body:ATM:Height
{
    set s_Val to Ship:Prograde.
    DispLaunchTelemetry().
    DispLaunchTelemetry().
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
                DispLaunchTelemetry().
                DispLaunchTelemetry().
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

local function ExecLoopEventDelegates
{
    local EventSet to g_LoopDelegates["Events"].
    if EventSet:Keys:Length > 0
    {
        for ev in EventSet:Keys
        {
            if EventSet[ev]:HasKey("Delegate")
            {
                EventSet[ev]:Delegate:Call().
            }
            else if EventSet[ev]:HasKey("CheckDel")
            {
                if EventSet[ev]:CheckDel:Call() 
                {
                    EventSet[ev]:ActionDel:Call().
                }
            }
        }
    }
}

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
        // set del to { if Ship:Altitude >= sounderStartTurn { local apo_err to Ship:Apoapsis / tgtAlt. set s_Val to Heading(g_MissionTag:Params[0], LaunchAngForAlt(tgtAlt, sounderStartTurn, 0, 5 + (10 * apo_err)), 0.925). } else { set s_Val to Heading(compass_for(Ship, Ship:Facing), 90, 0). }}.
        local _delDependency to InitAscentAng_Next(tgtAlt).
        set del to { if Ship:Altitude >= sounderStartTurn { local apo_err to Ship:Apoapsis / tgtAlt. set s_Val to Heading(g_MissionTag:Params[0], GetAscentAng_Next(_delDependency), 0.925). } else { set s_Val to Heading(compass_for(Ship, Ship:Facing), 90, 0). }}.
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




local function ArmBoosterStaging
{
    set g_BoosterObj to lexicon().

    local BoosterParts to Ship:PartsTaggedPattern("(^booster(\.|\|))+(as(\.|\|))?\d*$").

    local setIdxList to UniqueSet().
    if BoosterParts:Length > 0
    {
        for p in BoosterParts
        {
            local setIdx to p:Tag:Replace("booster",""):Replace("as",""):Replace(".",""):Replace("|",""):ToNumber(0).
            set g_BoosterObj[setIdx] to ProcessBoosterTree(p, setIdx, g_BoosterObj).
            if setIdxList:Contains(setIdx)
            {
            }
            else 
            {
                setIdxList:Add(setIdx).
            }
        }
        set g_BoostersArmed to true.
        return g_BoostersArmed.
    }
    else 
    {
        set g_BoostersArmed to false.
        return g_BoostersArmed.
    }
}


local function GetBoosterUpdateDel
{
    local updateDel to 
    { 
        for bp in Ship:PartsTaggedPattern("(^booster(\.|\|))+(as(\.|\|))?\d*$")
        {
            local setIdx to bp:Tag:Replace("booster",""):Replace("as",""):Replace(".",""):Replace("|",""):ToNumber(0).
            if g_BoosterObj:HasKey(setIdx) 
            { 
                if g_BoosterObj[setIdx]:HasKey("ENG") 
                {
                    set g_BoosterObj[setIdx]["ENG"]:ALLTHRUST to 0.
                    set g_BoosterObj[setIdx]["ENG"]:AVLTHRUST to 0.
                }
            }
            set g_BoosterObj to ProcessBoosterTree(bp, setIdx, g_BoosterObj).
        }
        return g_BoosterObj.
    }.
    return updateDel@.
}

local function ProcessBoosterTree
{
    parameter _p,
              _setIdx,
              _boosterObj.

    local dc to _p.
    if not _p:IsType("Decoupler")
    {
        set dc to _p:Decoupler.
    }

    local m to choose dc:GetModule("ModuleAnchoredDecoupler") if dc:HasModule("ModuleAnchoredDecoupler") else dc:GetModule("ModuleDecouple").
    local event to "".
    for _e in m:AllEvents
    {
        if _e:MatchesPattern("\(callable\).*decouple.*is KSPEvent")
        {
            set event to _e:Replace("(callable) ",""):Replace(", is KSPEvent","").
        }
    }
    
    // This resets the lex for each loop
    if not _boosterObj:HasKey(_setIdx)
    {
        set _boosterObj[_setIdx] to lexicon(
            "DC", lex(
                dc:UID, lex(
                    "P", dc
                    ,"M", m
                    ,"E", event
                    ,"S", dc:Stage
                )
            )
            ,"UPDATE", GetBoosterUpdateDel()
        ).
    }
    else
    {
        if not _boosterObj[_setIdx]:HasKey("DC")
        {
            set _boosterObj[_setIdx]["DC"] to lexicon().
        }
        
        set _boosterObj[_setIdx]["DC"][dc:UID] to lexicon(
            "P", dc
            ,"M", m
            ,"E", event
            ,"S", dc:Stage
        ).

        if not _boosterObj[_setIdx]:HasKey("UPDATE")
        {
            set _boosterObj[_setIdx]["UPDATE"] to GetBoosterUpdateDel().
        }
    }
    
    // Check to see if we need to airstart this booster set
    local as to false.
    if _p:Tag:Split("|"):Length > 2
    {
        if _p:Tag:Split("|")[1] = "as"
        {
            set as to true.
        }
    } 
    else if _p:Tag:Split("."):Length > 2
    {
        if _p:Tag:Split(".")[1] = "as" 
        {
            set as to true.
        }
    }
    set _boosterObj[_setIdx]["AS"] to as.


    for child in dc:Children
    {
        set _boosterObj to ProcessBoosterChildren(child, _setIdx, _boosterObj).
    }
    // if _boosterObj[setIdx]["RES"]:HasSuffix("AMOUNT")
    // {
    //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to Round(_boosterObj[setIdx]["RES"]:AMOUNT / _boosterObj[setIdx]["RES"]:CAPACITY, 5).
    // }
    // else
    // {
    //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to 1.
    // }

    return _boosterObj.
}





local function ProcessBoosterChildren
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Child for (Set): [{0}] ({1})":Format(_p:Name, _setIdx), 1).

    local _bcObj to _boosterObj.
    if not _p:HasModule("ProceduralFairingDecoupler")
    {
        if _p:IsType("Engine")
        {
            set _bcObj to ProcessBoosterEngine(_p, _setIdx, _bcObj).
        }
        else if _p:HasModule("ModuleFuelTank")
        {
            set _bcObj to ProcessBoosterTank(_p, _setIdx, _bcObj).
        }
        
        if _p:Children:Length > 0
        {
            for _child in _p:Children
            {
                set _bcObj to ProcessBoosterChildren(_child, _setIdx, _bcObj).
            }
        }
    }
    
    return _bcObj.
}





local function ProcessBoosterEngine
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Engine: [{0}]":Format(_p:Name), 1).

    local _beObj to _boosterObj.
    
    if not _beObj[_setIdx]:HasKey("ENG")
    {
        set _beObj[_setIdx]["ENG"] to lexicon(
            "ALLTHRUST", 0
            ,"AVLTHRUST", 0
            ,"PCTTHRUST", 0
            ,"PARTS", lex()
        ).
    }
    if not _beObj[_setIdx]:HasKey("SEP")
    {
        set _beObj[_setIdx]["SEP"] to lexicon().
    }

    if g_PartInfo:Engines:SEPREF:Contains(_p:Name) and _p:Tag:Length = 0
    {
        set _beObj[_setIdx]["SEP"][_p:UID] to _p.
    }
    else
    {
        local curThr  to _p:Thrust.
        local avlThr  to _p:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)).

        set _beObj[_setIdx]["ENG"]["PARTS"][_p:UID] to lexicon(
            "P", _p
            ,"M", _p:GetModule("ModuleEnginesRF")
            ,"S", _p:Stage
            ,"T", _p:Config
        ).
        set _beObj[_setIdx]["ENG"]:ALLTHRUST to _beObj[_setIdx]["ENG"]:ALLTHRUST + curThr.
        set _beObj[_setIdx]["ENG"]:AVLTHRUST to _beObj[_setIdx]["ENG"]:AVLTHRUST + avlThr.
        // set _beObj[_setIdx]["ENG"]:PCTTHRUST to Round(max(_beObj[_setIdx]["ENG"]:ALLTHRUST, 0.00000001) / max(_beObj[_setIdx]["ENG"]:AVLTHRUST, 0.0001), 4).
    }

    return _beObj.
}





local function ProcessBoosterTank
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Tank: [{0}]":Format(_p:Name), 1).

    local _btObj to _boosterObj.
    if not _btObj[_setIdx]:HasKey("TANK")
    {
        set _btObj[_setIdx]["TANK"] to lexicon().
    }

    set _btObj[_setIdx]["TANK"][_p:UID] to lexicon(
        "P", _p
        ,"M", _p:GetModule("ModuleFuelTank")
    ).
    set _btObj to ProcessBoosterTankResources(_p, _btObj).

    return _btObj.
}




local function ProcessBoosterTankResources
{
    parameter _p,
              _setIdx,
              _boosterObj.

    local _brObj to _boosterObj.

    if not _brObj[_setIdx]:HasKey("RES")
    {
        set _brObj[_setIdx]["RES"] to lexicon(
            "AMOUNT", 0
            ,"CAPACITY", 0
            ,"RESLIST", list()
        ).
    }

    for _res in _p:Resources
    {
        _brObj[_setIdx]["RES"][_res:Name]:RESLIST:Add(_res).
        set _brObj[_setIdx]["RES"][_res:Name]:AMOUNT to Round(_brObj[_setIdx]["RES"][_res:Name]:AMOUNT + _res:Amount, 5).
        set _brObj[_setIdx]["RES"][_res:Name]:CAPACITY to Round(_brObj[_setIdx]["RES"][_res:Name]:CAPACITY + _res:Capacity, 5).
    }
    return _brObj.
}




local function CheckBoosterStageCondition
{
    parameter _pctThresh to 0.025.

    if g_BoostersArmed 
    {

        // writeJson(g_BoosterObj, "0:/data/g_boosterobj.json").

        OutInfo("Boosters: [Armed(X)] [Set( )] [Cond( )]").
        if g_BoosterObj:Keys:Length > 0
        {
            local doneFlag to false.
            from { local i to 0.} until i = g_BoosterObj:Keys:Length or doneFlag step { set i to i + 1.} do
            {
                if not g_BoosterObj:Keys[i] = "UPDATE"
                {
                    local bSet to g_BoosterObj[g_BoosterObj:Keys[i]].
                    if bSet:HasKey("UPDATE") 
                    {
                        set g_BoosterObj to bSet:UPDATE:Call().
                        wait 0.01.
                        // writeJson(g_BoosterObj, Path("0:/data/g_BoosterObj.json")).
                        OutInfo("Boosters: [Armed(X)] [Set(X)] [Cond( )]").
                        // local check to bSet["RES"]["PCTLEFT"] <= _pctThresh.
                        // OutInfo("BoosterStageCondition: {0} ({1})":Format(check, bSet["RES"]["PCTLEFT"]), 2).
                        // if bSet["RES"]["PCTLEFT"] <= _pctThresh
                        // if bSet["ENG"]:Values[0]:P:Thrust < 0.1
                        local bSetKey to bSet:Keys[i].
                        local engPresent to bSet:HasKey("Eng").
                        local allPresent to choose bSet["ENG"]:HasKey("AllThrust") if engPresent else false.
                        local avlPresent to choose bSet["ENG"]:HasKey("AvlThrust") if engPresent else false.

                        print "KEY [{0}] | ENG [{1}] | ALL [{2}] | AVL [{3}]":Format(bsetKey, engPresent, allPresent, avlPresent) at (0, 35).
                        set ThrustThresh to Max(ThrustThresh, bSet["ENG"]:AVLTHRUST * _pctThresh).
                        OutInfo("THRUST: {0} ({1})":Format(Round(bSet["ENG"]:ALLTHRUST, 2), Round(ThrustThresh, 2)), 1).
                        if bSet["ENG"]:ALLTHRUST < ThrustThresh
                        {
                            OutInfo("Boosters: [Armed(X)] [Set(X)] [Cond(X)]").
                            StageBoosterSet(i).
                            // set bSet to "".
                            wait 0.025.
                            g_BoosterObj:Remove(i).
                            wait 0.01.
                            
                            if g_BoosterObj:Keys:Length < 1
                            {
                                set g_BoostersArmed to false.
                            }
                            else
                            {
                                
                            }
                            set doneFlag to true.
                        }
                    }
                }
            }
        }
        else
        {
            set g_BoostersArmed to false.
        }
    }
}





local function StageBoosterSet
{
    parameter _setIdx.

    if g_BoosterObj:HasKey(_setIdx)
    {
        // local stgSet to g_BoosterObj[_setIdx].
    
        for eng in g_BoosterObj[_setIdx]["ENG"]:Parts:Values
        {
            if eng:P:Ignition and not eng:P:Flameout
            {
                eng:P:Shutdown.
            }
        }
        wait 0.01.
        for sep in g_BoosterObj[_setIdx]["SEP"]:Values
        {
            DoEvent(sep:GetModule("ModuleEnginesRF"), "activate engine").
            wait 0.01.
        }
        wait 0.01.
        for dc in g_BoosterObj[_setIdx]["DC"]:Keys
        {
            DoEvent(g_BoosterObj[_setIdx]["DC"][dc]:M, g_BoosterObj[_setIdx]["DC"][dc]:E).
        }
        wait 0.01.

        // Check for AirStarts in the next booster set if present
        if g_BoosterObj:HasKey(_setIdx + 1)
        {
            if g_BoosterObj[_setIdx + 1]:AS
            {
                for eng in g_BoosterObj[_setIdx + 1]["ENG"]:Parts:Values
                {
                    if not eng:P:Ignition
                    {
                        eng:P:Activate.
                    }
                }
            }
        }
        wait 0.01.
        // wait until Stage:Ready.
        // Stage.
        return true.
    }
    else
    {
        return false.
    }
    
}


local function CheckBoosterStaging_Old
{
    parameter _boosterIdx is 0.
              
    local booster_index to _boosterIdx.
    set curBoosterTag   to "booster.{0}":Format(booster_index).
    local boosterParts  to Ship:PartsTagged(curBoosterTag).
    if boosterParts:Length > 0
    {
        set cb to boosterParts[0]. // cb = CheckBooster
        if cb:IsType("Decoupler")
        {

        }
        else if cb:IsType("Engine")
        {
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
                    set boostersArmed to false.
                }
                else
                {
                    set booster_index to booster_index + 1.
                }
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