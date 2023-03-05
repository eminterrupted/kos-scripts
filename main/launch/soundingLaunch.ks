@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/depLoader.ks").

local clampStage to Ship:ModulesNamed("LaunchClamp")[0]:Part:Stage.

local boostersActive to false.
local boosterIdx     to 0.
local cb             to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag  to "".

Breakpoint(Terminal:Input:Enter, "*** Press ENTER to launch ***").
ClearScreen.
OutMsg("Launch initiated!").
lock Throttle to 1.
wait 0.25.
set g_StageEngines_Next to GetEnginesForStage(Stage:Number - 1).
wait 0.01.
stage.
wait GetField(g_StageEngines_Next[0]:GetModule("ModuleEnginesRF"), "effective spool-up time", 0).

until Stage:Number <= clampStage
{
    wait until Stage:Ready.
    stage.
    wait 1.
}

set g_StageEngines_Current to GetEnginesForStage(Stage:Number).
set g_StageEngines_Next to GetEnginesForStage(Stage:Number - 1).

until Stage:Number = g_StageLimit
{
    // local cbCousins      to list().
    set g_StageEngines_Active to GetActiveEngines().
    for p in g_StageEngines_Active
    {
        if p:Tag:MatchesPattern("Booster.\d*")
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

                if cb:Thrust <= 0.001
                {
                    for i in Range (0, cb:SymmetryCount - 1, 1)
                    {
                        cb:SymmetryPartner(i):Shutdown.
                    }
                    wait until Stage:Ready.
                    stage.
                    wait 0.01.
                
                    if Ship:PartsTaggedPattern("booster.\d*"):Length = 0
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
    }

    if Ship:AvailableThrust <= 0.01
    {
        if Stage:Ready
        {
            Stage.
            wait 0.05.
        }
    }

    OutInfo("Altitude: {0}m ":Format(Round(Ship:Altitude))).
    wait 0.01.
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







// GetActiveEngines :: [(_ves)<Ship>] -> (ActiveEngines)<List)
// Returns a list of engines current firing and with a stage number great than the current one
global function GetActiveEngines
{
    parameter _ves is Ship.

    local engList to list().
    for eng in _ves:Engines
    {
        if eng:ignition
        {
            if not eng:flameout
            {
                if eng:stage >= Stage:Number
                {
                    engList:Add(eng).
                }
            }
        }
    }

    return engList.
}


// GetEnginesForStage :: (Stage Number)<scalar> -> (Engines activated by that stage)<List>
// Returns engines for a given stage number
global function GetEnginesForStage
{
    parameter _stg.

    local engList to list().

    for eng in ship:engines
    {
        if eng:Stage = _stg 
        { 
            engList:Add(eng). 
        }
    }
    return engList.
}

// GetEngineDetails :: (Engine)<Engine> -> (Details Object)<Lexicon>
// Returns a set of useful details about this engine such as spool time, ullage requirement, and max mass and fuel flows
global function GetEngineDetails
{
    parameter _eng.

    local m to _eng:GetModule("ModuleEnginesRF").
    local engLex to lexicon(
        "ENGTITLE",        _eng:Title
        ,"ENGNAME",         _eng:Name
        ,"IGNITIONS",       GetField(m, "ignitions remaining", 0)
        ,"MIXRATIO",        GetField(m, "mixture ratio", 0)
        ,"FUELSTABILITY",   GetField(m, "propellant", "")
        ,"RESIDUALS",       GetField(m, "predicted residuals", 0)
        ,"SPOOLTIME",       GetField(m, "effective spool-up time", 0)
        ,"STATUS",          GetField(m, "status", "")
        ,"ULLAGE",          _eng:Ullage
    ).
    return engLex.
}


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