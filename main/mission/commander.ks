@LazyGlobal off.
ClearScreen.

// Load dependencies
RunOncePath("0:/lib/libLoader.ks").

// Define high-level variables
local doneFlag to False.
local preLaunchFlag to True.

ParseCoreTag().

if Ship:Status = "PRELAUNCH"
{
    RunPath("0:/_plan/setup.ks").
}
else
{
    set preLaunchFlag to False.
}

until g_PlanLex:Keys:Length = 0
{
    RunPath("0:/main/{0}":Format(g_PlanLex:Keys[0]), g_PlanLex:Values[0]).
    g_PlanLex:Remove(g_PlanLex:Keys[0]).
}

// TODO: Plan Cleanup