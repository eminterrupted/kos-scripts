@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose params[0] if params:Length > 0 else choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAp        to choose params[1] if params:Length > 1 else choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 175000.
local tgtPe        to choose params[2] if params:Length > 2 else choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 and g_MissionTag:Params[2] >  1 else -1.
local tgtEcc       to choose params[3] if params:Length > 3 else choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 and g_MissionTag:Params[2] <= 1 else -1. 
local azObj        to choose params[4] if params:Length > 4 else choose l_az_calc_init(tgtAp, tgtInc) if g_GuidedAscentMissions:Contains(g_MissionTag:Mission) else list().

OutMsg("Ready for launch...").

local launchTargetDispObj to GetLaunchParameters().
DispLaunchConfigData(launchTargetDispObj).


local l_LaunchLAN to GetTrueAnomaly(Ship).
local l_tgtLAN    to choose target:Orbit:LAN if HasTarget else l_LaunchLAN.

local l_CSVPath   to "0:/log/launch/{0}.csv":Format(Ship:Name:Replace(" ","_")).
local l_CSVInit   to InitCSV(l_CSVPath, AggregateLogData()).


local coreMsgs to Core:Messages.
local skipFlag to False.

OutInfo("Waiting for countdown").
until Ship:Status <> "PRELAUNCH" or skipFlag
{
    until coreMsgs:Empty
    {
        local msg to coreMsgs:Pop().
        {
            DispCoreMessage(msg).
            if msg:Content = "P03_COUNTDOWN"
            {
                set skipFlag to True.
            }
        }
    }
    wait 0.01.
}
set skipFlag to False.

// Start logging data
OutInfo("Logging Started").
until skipFlag
{
    OutCSV(AggregateLogData()).

    until coreMsgs:Empty
    {
        local msg to coreMsgs:Pop().
        {
            DispCoreMessage(msg).
            if msg:Content = "P63_ORBIT"
            {
                set skipFlag to True.
            }
        }
    }
    wait 0.01.
}
OutInfo().
OutMsg("Done!").
wait 5.



local function AggregateLogData
{
    local curGeoPos to Ship:GeoPosition.
    local curDist   to (curGeoPos:Position - g_LaunchSiteGeo:Position):Mag.
    local curInc    to Ship:Orbit:Inclination.
    
    local logObj to lexicon(
        "PROGRAM",                      "P" + g_Program
        ,"ALTITUDE_ASL",                Ship:Altitude
        ,"ALTITUDE_RDR",                Ship:Altitude - curGeoPos:TerrainHeight
        ,"SURFACE VELOCITY",            Ship:Orbit:Velocity:Surface:Mag
        ,"ORBITAL VELOCITY",            Ship:Orbit:Velocity:Orbit:Mag
        ,"VERTICAL SPEED",              Ship:VerticalSpeed
        ,"GROUND SPEED",                Ship:groundspeed
        ,"PRESSURE ATM",                Ship:Body:ATM:AltitudePressure(Ship:Altitude)
        ,"PRESSURE KPA",                Ship:Body:ATM:AltitudePressure(Ship:Altitude) * Constant:ATMtoKPA
        ,"PRESSURE DYNAMIC",            Ship:DynamicPressure
        ,"LAUNCH_LAN",                  l_launchLAN
        ,"EFFECTIVE_LAN",               Ship:Orbit:LAN
        ,"TARGET_LAN",                  l_tgtLAN
        ,"INCLINATION",                 curInc
        ,"GEOPOSITION_LAT",             curGeoPos:LAT
        ,"GEOPOSITION_LNG",             curGeoPos:LNG
        ,"GEOPOSITION_TERRAINHEIGHT",   curGeoPos:TerrainHeight
        ,"DISTANCE_TO_LAUNCHSITE",      curDist
    ).

    return logObj.
}





local function InitCSV
{
    parameter _csvPath to "0:/log/{0}":Format(Ship:Name:Replace(" ","_")),
              _logObj to lexicon("DEF","").

    local str to "UT,MET".

    for colKey in _logObj:Keys
    {
        set str to "{0},{1}":Format(str, colKey).
    }

    if Exists(_csvPath)
    {
        MovePath(_csvPath, _csvPath:Replace(".json", ".{0}.json":Format(Round(Time:Seconds)))).
    }

    log str to _csvPath.
    set l_CSVPath to _csvPath.

    return Exists(_csvPath).
}


local function OutCSV
{
    parameter _logObj to lexicon().

    if l_CSVInit
    {
        local str to "{0},{1}":Format(Round(Time:Seconds, 5), Round(MissionTime, 5)).
        for colVal in _logObj:Values
        {
            set str to str + ",{0}":Format(colVal).
        }
        Log str to l_CSVPath.
    }
}