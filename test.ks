@lazyGlobal off.
clearScreen.

parameter _prms to list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

print "Testing TestBuildList".
print TestBuildList().

print " ".

print "Testing TestShipList".
print TestShipList().

print " ".


// local script to "". // Path to test script.
// local scriptPrms to _prms. // parameters for script
// if _prms:Length > 0 
// {

// }
// runPath("").

// local eng to ship:partsNamed("ROE-Aerobee")[0].
// local l_line to 0.
// local l_col to 3.
// global g_frameCounterLine to 0.
// // The dictionary

// if _prms:IsType("String")
// {
//     set _prms to _prms:split(";").

// }
// else if _prms:IsType("List")
// {
// }

// if _prms:Length > 0 
// {
//     set eng to _prms[0].
// }

// local doneFlag to false.

// DispTestHeader().
// InitDataObj(eng).
// local engData to lexicon().  // This will hold our data object from the engine in question
// local frameCount to 0.

// // Main loop
// until doneFlag
// {
//     GetTermChar().
//     if g_TermChar <> ""
//     {
//         if g_TermChar = Terminal:Input:endCursor
//         {
//             set doneFlag to true.
//             break.
//         }
//         else if g_TermChar = Terminal:Input:deleteright
//         {
//             clearScreen.
//             DispTestHeader().
//             set frameCount to 0.
//         }
//     }

//     if frameCount > 60 
//     {
//         clearScreen.
//         DispTestHeader().
//         set frameCount to 0.
//     }
//     engData:clear().
//     set engData to RefreshData(eng).
//     DispLexiconData(engData, l_line).
//     set frameCount to frameCount + 1.
    
//     print "[{0}]":format(frameCount) at (15, g_frameCounterLine).
//     wait 0.01.
// }
// print "*** Script Complete! ***" at (5, Terminal:height - 2).




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
              _startLine is g_line.

    set g_line to _startLine.
    
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
        "CID",          _eng:Cid,
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