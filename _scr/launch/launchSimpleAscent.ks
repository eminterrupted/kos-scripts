@LazyGlobal off.
ClearScreen.

parameter params to list().

runOncePath("0:/lib/loadDep").

DispMain(ScriptPath()).

local tgt_alt to -1.
local tgt_hdg to 90.

local eng to choose ship:partsTagged("ullageTest")[0] if ship:partsTagged("ullageTest"):length > 0 else ship:engines[0].

global g_EngDataObj to InitDataObj(eng).

local nextStg to stage:number - 1.

OutMsg("Press SPACE to go to SPACE!").
until stage:number = nextStg
{
    wait 0.01.
}
OutMsg("Launch Commit!").
OutInfo("Yay, you did it").
OutInfo("", 1).
wait 0.01.
set nextStg to stage:number - 1.

until false
{
    OutMsg("Launch Ascent  ").
    if ship:availableThrust < 0.01
    {
        OutInfo("We are entering AerobeeSafeStage()", 1).
        AerobeeSafeStage().
        OutInfo("We are exiting AerobeeSafeStage()", 1).
    }
    else
    {
        OutInfo("ALTITUDE (AP)       : {0}m ({1}m)    ":format(round(ship:altitude), round(ship:apoapsis)), 0).
        OutInfo("VELOCITY (SRF (OBT)): {0}m/s ({1}m/s)   ":format(round(ship:velocity:surface:mag, 1), round(ship:velocity:orbit:mag, 1)), 1).
        set g_EngDataObj to GetEngineData(eng).
        //DispEngineData(g_EngDataObj).
    }
    wait 0.01.
}



local function GetActiveEngines2
{
    parameter _ves is ship.

    local _engList to list().

    for _e in _ves:engines
    {
        if _e:ignition and not _e:flameout _engList:add(_e).
    }
    
    return _engList.
}



local function AerobeeSafeStage
{   
    // OutInfo("[AerobeeSafeStage] stage:number [<{0}>{1}] > g_stopStage [<{2}>{3}]":format(stage:number:typename, stage:number, g_stopStage:typename, g_stopStage), 1).
    // Breakpoint().
    if stage:number > g_stopStage
    {   
        OutInfo("[AerobeeSafeStage] stage:number [{0}] > g_stopStage [{1}]":format(stage:number, g_stopStage), 1).

        OutMsg("Staging").
        OutInfo("[AerobeeSafeStage] Waiting until stage ready...").
        until stage:ready
        {
            set g_EngDataObj to GetEngineData(eng).
            //DispEngineData(g_EngDataObj). 
        }
        OutInfo("[AerobeeSafeStage] Wait over, staging").
        stage. 
        OutInfo("", 1).
        wait 0.05. // Wait a bit to ensure we are getting data from the new engines
        
        OutInfo("[AerobeeSafeStage] Refreshing g_activeEngines").
        set g_activeEngines to ActiveEngines(ship, true). // Refresh the active engines
        wait 0.05.  // Wait a bit to ensure we are getting data from the new engines

        set g_idx to 0.
        set g_ts to time:seconds + 0.50.
        local _ts_2 to time:seconds + 0.100.
        local _ts_3 to time:seconds + 0.125.

        local _strArr to list(
            "     Ignition     ",
            "     Ignition     ",
            "   * Ignition *   ",
            "  ** Ignition **  ",
            "  ** Ignition **  ",
            " *** Ignition *** ",
            " *** Ignition *** ",
            " *** Ignition *** ",
            "-*** Ignition ***-",
            "-*** Ignition ***-",
            "-*** Ignition ***-",
            "-*** Ignition ***-",
            "-*** Ignition ***-",
            " *** Ignition *** ",
            " *** Ignition *** ",
            " *** Ignition *** ",
            "  ** Ignition **  ",
            "  ** Ignition **  ",
            "   * Ignition *   ",
            "     Ignition     ",
            "     Ignition     "
        ).

        OutInfo(_strArr[g_idx]).
        local doneFlag to false.
        set _ts_2 to time:seconds + 0.325.
        OutInfo("[AerobeeSafeStage] 2nd until loop", 1).
        until doneFlag or time:seconds > g_ts 
        {    
            OutInfo("[AerobeeSafeStage][120] Refreshing g_activeEngines()", 1).
            set g_activeEngines to ActiveEngines().
            if g_activeEngines["Engines"]:SEPSTG
            {
                OutInfo("SEP STAGE ACTIVE").
                OutInfo("[AerobeeSafeStage][125] SEPSTG: Entering second staging loop", 1).
                
                if time:seconds < _ts_2
                {
                    set g_idx to mod(g_idx + 1, 21).
                    OutInfo(_strArr[g_idx]).
                    wait 0.025.
                }
                else
                {
                    wait until stage:ready.
                    OutInfo("[AerobeeSafeStage][129] Second staging ready", 1).
                    stage.
                    OutInfo("[AerobeeSafeStage][131] Second staging complete", 1).
                    wait 0.075.
                    OutInfo("[AerobeeSafeStage][133] Refreshing g_activeEngines", 1).
                    set g_activeEngines to ActiveEngines().
                    set doneFlag to true.
                }
            }
            else
            {
                OutInfo("[AerobeeSafeStage][140] No SEPSTG, waiting for sufficient thrust", 1).
                if CheckPctRange(g_activeEngines["CURTHRUST"], g_activeEngines["AVLTHRUST"], 0.50, 1)
                {
                    set doneFlag to true.
                }
                else
                {
                    if time:seconds > _ts_2
                    {
                        set g_idx to mod(g_idx + 1, 21).
                        OutInfo(_strArr[g_idx]).
                    }
                }
            }
        }
        OutInfo().
        OutMsg("Staging complete").     
    }
}



// CheckPctRange :: <scalar>_numIn - Numerator; <scalar>_denomIn - Denominator; <scalar>_tgtVal - Value to check against; <scalar>_padVal - optional "slop" value -> <bool>
// Checks a set of related values for the percentage between the two, and returns a bool based on proximity to the provided _tgtPctVal
local function CheckPctRange
{
    parameter _numIn,
              _denomIn,
              _tgtPctVal is 1,  // Fractional percentage  (1 = 100%, 0.5 = 50%, etc)
              _padPctVal is 1.  // Fractional percentage unique value, if set to 1 or higher, that just means "anything that's 
                                // positive relative to the tgt value"; Likewise, a number LEQ -1 means any number below the tgt value.

    local _pct to max(0.0000000001, _numIn) / max(0.000000000001, _denomIn).

    if _padPctVal >= 1          return _pct >= _tgtPctVal.
    else if _padPctVal <= -1    return _pct <= _tgtPctVal.
    else                        return (_pct >= (_tgtPctVal - _padPctVal)) and (_pct <= (_tgtPctVal + _padPctVal)).
}



//local function DispLexiconData
local function DispEngineData
{
    parameter _objToDisplay, 
              _startLine is g_line.

    set g_line to _startLine.
    
    from { local i to 0.} until i = _objToDisplay:keys:length step { set i to i + 1.} do 
    {
        local _key to _objToDisplay:keys[i].
        local _val to _objToDisplay[_key].

        if _key:matchesPattern("^\*\*\*.*")
        {
            print _key at (0, cr()).
            cr().
            for idx in range(0, _key:length, 1)
            {
                print _val at (idx,g_line).
            }
        }
        else if _key:matchesPattern("^cr_\d*")
        {
            cr().
        }
        else
        {
            local _valFormatted to _val.
            if _val:IsType("Scalar")
            {   
                set _valFormatted to round(_valFormatted, 5).
            }
            else if _val:IsType("List")
            {
                set _valFormatted to _val:join(";").
            }
            
            print "{0,-20}: [{1,-30}]   ":format(_key, _valFormatted) at (3, cr()).
        }
    }
}




local function InitDataObj
{
    parameter _eng, _dataObj to lexicon().

    if defined g_EngData unset g_EngData. 
    global g_EngData to GetEngineData(_eng).
    return g_EngData.
}



// Refreshes the provided data object with the provided engine data
local function GetEngineData
{
    parameter _eng.

    local pres to Body:Atm:AltitudePressure(Ship:Altitude).

    // Special-case engine variables

    local _eng_Mode         to "N/A".
    local _eng_PrimaryMode  to "N/A".
    local _eng_Modes        to list("N/A").
    local _eng_AutoSwitch   to "N/A".

    if _eng:MultiMode
    {
        set _eng_Mode        to _eng:Mode.
        set _eng_PrimaryMode to _eng:PrimaryMode.
        set _eng_Modes       to _eng:Modes:Join(";").
        set _eng_AutoSwitch  to _eng:AutoSwitch.
    }

    local suffixLex to lexicon(
        // Engine details
        "***INFO",      "-",
        "NAME",         _eng:Name,
        "TITLE",        _eng:Title,
        //"CID",          _eng:Cid,
        "STAGE",        _eng:Stage,
        "DECOUPLEDIN",  _eng:DecoupledIn,
        // "ROTATION",     _eng:Rotation,
        "cr_0", "",

        // Engine status
        "***STATUS",    "-",
        "IGNITION",     _eng:Ignition,
        "IGNITIONS",    _eng:Ignitions,
        "FLAMEOUT",     _eng:Flameout,
        "cr_1", "",

        // Fuel monitoring
        "***FUEL SYSTEM",   "-",
        "ULLAGE",           _eng:Ullage,
        "PRESSUREFED",      _eng:PressureFed,
        "FUELSTABILITY",    _eng:FuelStability,
        "FUELFLOW",         _eng:FuelFlow,
        "MAXFUELFLOW",      _eng:MaxFuelFlow,
        "MASSFLOW",         _eng:MassFlow,
        "MAXMASSFLOW",      _eng:MaxMassFlow,
        //"CONSUMEDRESOURCES",
        "cr_2", "",
        // Engine Capabilities
        "***ENGINE CAPABILITIES", "-",
        //"MINTHROTTLE",      _eng:MinThrottle,
        "ALLOWRESTART",     _eng:AllowRestart,
        "ALLOWSHUTDOWN",    _eng:AllowShutdown,
        // "THRUSTLIMIT",      _eng:ThrustLimit,
        // "THROTTLELOCK",     _eng:ThrottleLock,
        // "MULTIMODE",        _eng:MultiMode,
        // "MODE",             _eng_Mode,          // Because this will fail if engine 
        // "PRIMARYMODE",      _eng_PrimaryMode,   // engine is not multimode, use our 
        // "MODES",            _eng_Modes,         // pre-formatted values to safeguard
        // "AUTOSWITCH",       _eng_AutoSwitch,    // against this.
        "cr_3", "",
        // ISP
        "***ISP PERFORMANCE",    "-",
        //"ISP",                  _eng:Isp,
        "ISPAT",                _eng:ISPAt(pres),
        //"SEALEVELISP",          _eng:SeaLevelISP,
        //"VACUUMISP",            _eng:VacuumISP,
        "cr_5", "",
        // Thrust Table
        "***THRUST VALUES",     "-",
        "THRUST",               _eng:Thrust,
        "cr_6", "",
        //"AVAILABLETHRUST",      _eng:AvailableThrust,
        "AVAILABLETHRUSTAT",    _eng:AvailableThrustAt(pres),
        "cr_7", "",
        //"MAXPOSSIBLETHRUST",    _eng:MaxPossibleThrust,
        "MAXPOSSIBLETHRUSTAT",  _eng:MaxPossibleThrustAt(pres),
        "cr_8", "",
        //"MAXTHRUST",            _eng:MaxThrust,
        "MAXTHRUSTAT",          _eng:MaxThrustAt(pres),
        "cr_9", "",
        //"POSSIBLETHRUST",       _eng:PossibleThrust,
        "POSSIBLETHRUSTAT",     _eng:PossibleThrustAt(pres)
    ).

    return suffixLex.
}