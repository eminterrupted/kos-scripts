@LazyGlobal off.
ClearScreen.

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/sci").

parameter params to list().

local tgtPe to ship:periapsis.

local doSci to true.
local sciSitu to "all". // Valid values: HIGH (high space) | LOW (low space) | ALL (both)
local sciAction to "ideal". // Valid values: TRANSMIT (force transmit) | COLLECT (store) | IDEAL (transmit if gets max sci, store if not)
local sciModules to GetSciModules().

local warpFlag to false.

DispMain(ScriptPath()).

if params:length > 0
{
    set g_orientation to params[0].
    if params:length > 1 set tgtPe to params[1].
    if params:length > 2 set doSci to params[2].
    if params:length > 3 set sciSitu to params[3].
    if params:length > 4 set sciAction to params[4].
}

lock steering to GetSteeringDir(g_orientation).

// TO-DO: Write code to lower to desired flyby alt

if ship:altitude >= BodyInfo:altForSci[Body:Name]
{
    if doSci and (sciSitu = "all" or sciSitu = "high")
    {
        SciRoutine().
    }
    OutMsg().
}

local timeToPe to time:seconds + eta:periapsis.
OutInfo2("Press ENTER to warp to PE").
until time:seconds >= timeToPe
{
    if CheckWarpKey()
    {
        OutInfo2().
        InitWarp(timeToPe, "closest approach to " + Body:Name).
    }
    DispFlyBy().
}
clrDisp().

local caAlt     to Ship:Altitude.
local caRdr     to Ship:Bounds:BottomAltRadar.
local caVelo    to Ship:Orbit:Velocity:Orbit:Mag.

OutInfo("Closest approach: " + ship:altitude).
OutInfo2("Ground Periapsis: " + ship:bounds:bottomaltradar).
wait 2.5.

if doSci and (sciSitu = "all" or sciSitu = "low")
{
    SciRoutine().
}

OutMsg("Flyby mission complete!").
wait 2.5.

////
local function SciRoutine
{
    OutInfo2().
    DeployPartSet("sciDeploy", "deploy").
    OutInfo("Collecting science report").
    DeploySciList(sciModules).
    RecoverSciList(sciModules, sciAction).
    OutInfo("Science collected").
    wait 1.
    OutInfo().
}
