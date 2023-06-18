@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Load dependencies
RunOncePath("0:/lib/libLoader.ks").

// Define high-level variables
local tgtHeading to 90.
local tgtAngle   to 89.25.
local towerHeight to (Ship:Bounds:Size:Mag + 100).

// Parameter checking
if _params:length > 0 
{
    set tgtHeading to _params[0].
    if _params:length > 1 set tgtAngle to _params[1].
}

DispMain(ScriptPath()).
Breakpoint(Terminal:Input:Enter, "*** Press Enter to Launch ***").
ClearScreen.
DispMain(ScriptPath()).

// Begin
lock steering to s_Val.
lock throttle to t_Val.
OutMsg("Launch initiated").
LaunchCountdown(0.25).
OutInfo().
wait 0.01.

set g_ActiveEngines to GetActiveEngines().
set g_NextEngines   to GetNextEngines().
ArmAutoStaging().
wait 0.01.

local engineCounter to g_ActiveEngines:Length.

until false
{
    if engineCounter <> g_ActiveEngines:Length
    {
        set g_ActiveEngines to GetActiveEngines().
    } 
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    
    if g_LoopDelegates:HasKey("Staging")
    {
        set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
        if stagingCheckResult = 1
        {
            g_LoopDelegates:Staging["Action"]:Call().
        }
    }
    DispLaunchTelemetry().
    DispEngineTelemetry(g_ActiveEngines_Data).
}