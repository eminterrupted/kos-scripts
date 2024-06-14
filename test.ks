@lazyGlobal off.
clearScreen.

parameter _prms to list().

runOncePath("0:/lib/libLoader").
runOncePath("0:/lib/launch").


clearScreen.
wait 1.
local engList to list().
for eng in ship:engines { if eng:Name:MatchesPattern("ROE-NikeM5E1") engList:Add(eng).}
local dispList to list().
local line to 5.
until false {
  dispList:Clear().
  if MissionTime = 0 { dispList:Add("...Awaiting liftoff..."). wait 0.25.} else {  
    set line to 5.
    dispList:Add(" MET: {0}":Format(Round(MissionTime, 2))). //  at (2, line).
    dispList:Add(" ").
    for p in engList { dispList:Add(" [{0}]({1}) {2}/{3} | {4} | {5}     ":Format(p:name, p:Decoupler:Tag, p:Thrust, Round(p:GetModule("ModuleEnginesRF"):GetField("Thrust"), 1), Round(p:MaxMassFlow, 3), Round(p:Resources[0]:Amount / p:Resources[0]:Capacity, 4) * 100)).}
  }
  from { local i to 0.} until i = dispList:Length step { set i to i + 1.} do { print dispList[i] at (0, line + i).}
}

Breakpoint().











ArmAutoStaging(0).
local stagingCheckResult to lexicon().
local stagingDelegateAction to g_LoopDelegates:Staging:Action.

local steeringAction to { return LookDirUp(Ship:Prograde:Vector, -Body:Position) - R(0, 3, 0). }.
local steeringDel to steeringAction@.

lock steering to s_Val.

until ETA:Apoapsis <= 90
{
    set s_Val to steeringDel:Call().
    OutMsg("Time to AP: {0}":Format(Round(ETA:apoapsis, 2))).
    wait 0.01.
}
lock throttle to 1.

until Stage:Number = 0
{
    set s_Val to steeringDel:Call().
    set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
    if stagingCheckResult = 1
    {
        stagingDelegateAction:Call().
    }
}
lock throttle to 0.


// if _prms = list() 
// {
//     until false DispLexiconData(GetShipEnginesSpecs()).
// }
// else 
// {
//     until false DispLexiconData(GetEnginePerformanceData(_prms)).
// }


// Functions
local function DispTestHeader
{
    set g_line to 1.

    print "TEST SCRIPT v0.000001.001.0001 (Alpha(Beta))     " at (0, g_line).
    print "--------------------------------------------     " at (0, cr()).
    cr().
    print "TESTING     : Engine Suffixes     " at (0, cr()).
    print "FRAMECOUNTER: " at (0, cr()).
    set g_frameCounterLine to g_line.
    cr().
    set l_line to cr().
    set l_col to 3.
}

local function DispLexiconData
{
    parameter _objToDisplay, 
              _startLine is 10.

    set g_line to _startLine.
    local l_col to 0.

    from { local i to 0.} until i = _objToDisplay:keys:Length step { set i to i + 1.} do 
    {
        local _key to _objToDisplay:keys[i].
        local _val to _objToDisplay[_key].

        if _key:matchesPattern("^\*\*\*.*")
        {
            print _key at (0, cr()).
            cr().
            for idx in range(0, _key:Length, 1)
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
            
            print "{0,-20}: [{1,-30}]   ":format(_key, _valFormatted) at (l_col, cr()).
        }
    }
}


local function InitDataObj
{
    parameter _eng, _dataObj to lexicon().

    if defined g_EngData unset g_EngData. 
    global g_EngData to RefreshData(_eng).
    return g_EngData.
}

// Refreshes the provided data object with the provided engine data
local function RefreshData
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
        "UID",          _eng:UID,
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
        "FUELSTABILITY",    _eng:FuelStability,
        "FUELFLOW",         _eng:FuelFlow,
        "MAXFUELFLOW",      _eng:MaxFuelFlow,
        "MASSFLOW",         _eng:MassFlow,
        "MAXMASSFLOW",      _eng:MaxMassFlow,
        //"CONSUMEDRESOURCES",
        "cr_2", "",
        // Engine Capabilities
        "***ENGINE CAPABILITIES", "-",
        "ALLOWRESTART",     _eng:AllowRestart,
        "ALLOWSHUTDOWN",    _eng:AllowShutdown,
        "MINTHROTTLE",      _eng:MinThrottle,
        "THRUSTLIMIT",      _eng:ThrustLimit,
        "PRESSUREFED",      _eng:PressureFed,
        "THROTTLELOCK",     _eng:ThrottleLock,
        "MULTIMODE",        _eng:MultiMode,
        "MODE",             _eng_Mode,          // Because this will fail if engine 
        "PRIMARYMODE",      _eng_PrimaryMode,   // engine is not multimode, use our 
        "MODES",            _eng_Modes,         // pre-formatted values to safeguard
        "AUTOSWITCH",       _eng_AutoSwitch,    // against this.
        "cr_3", "",
        // ISP
        "***ISP PERFORMANCE",    "-",
        "ISP",                  _eng:Isp,
        "ISPAT",                _eng:ISPAt(pres),
        "SEALEVELISP",          _eng:SeaLevelISP,
        "VACUUMISP",            _eng:VacuumISP,
        "cr_5", "",
        // Thrust Table
        "***THRUST VALUES",     "-",
        "THRUST",               _eng:Thrust,
        "cr_6", "",
        "AVAILABLETHRUST",      _eng:AvailableThrust,
        "AVAILABLETHRUSTAT",    _eng:AvailableThrustAt(pres),
        "cr_7", "",
        "MAXPOSSIBLETHRUST",    _eng:MaxPossibleThrust,
        "MAXPOSSIBLETHRUSTAT",  _eng:MaxPossibleThrustAt(pres),
        "cr_8", "",
        "MAXTHRUST",            _eng:MaxThrust,
        "MAXTHRUSTAT",          _eng:MaxThrustAt(pres),
        "cr_9", "",
        "POSSIBLETHRUST",       _eng:PossibleThrust,
        "POSSIBLETHRUSTAT",     _eng:PossibleThrustAt(pres)
    ).

    return suffixLex.
}

local function TestBuildList
{
    local foo to "".

    local TS to Time:Seconds.
    set foo to BuildList("engines").
    set TS to Time:Seconds - TS.
    
    return foo.
}

local function TestShipList
{
    local foo to "".

    local TS to Time:Seconds.
    set foo to Ship:Engines.
    set TS to Time:Seconds - TS.
    
    return foo.
}