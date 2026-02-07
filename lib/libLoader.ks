@LazyGlobal off.
// This loader, well, loads stuff. 
// Specifically the libraries, and in a specific order

// Parameters can choose individual libs to load
parameter _params is list().

local filterLevel to 0. // 0 = all libraries, up to 3 being minimal libraries

if _params:Length > 0
{
    set filterLevel to Min(3, Max(0, _params[0])).
}

RunOncePath("0:/lib/globals.ks").
if filterLevel < 3
{
    RunOncePath("0:/lib/disp.ks").
    RunOncePath("0:/lib/util.ks").
}
if filterLevel < 2 
{
    RunOncePath("0:/lib/plan.ks").
    RunOncePath("0:/lib/log.ks").
    RunOncePath("0:/lib/events.ks").
}
if filterLevel < 1 
{
    RunOncePath("0:/lib/kslib/lib_navball.ks").
    RunOncePath("0:/lib/kslib/lib_navigation.ks").
    RunOncePath("0:/lib/nav.ks").
    RunOncePath("0:/lib/orbit.ks").
    RunOncePath("0:/lib/engines.ks").
    RunOncePath("0:/lib/abort.ks").
    RunOncePath("0:/lib/vessel.ks").
    RunOncePath("0:/lib/sci.ks").
    RunOncePath("0:/lib/staging.ks").
    RunOncePath("0:/lib/mnv.ks").
    RunOncePath("0:/lib/dvCalc.ks").
}

// Initiate any global objects here
if filterLevel < 1 
{
    set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).
}
else
{
    set g_ShipEngines_Spec to Lexicon("DISABLED", "DISABLED").
}
set g_UIDUpdaterArmed to SetupUpdateUIDEventHandler(True).

if g_Debug WriteJson(g_ShipEngines_Spec, "0:/data/debug/{0}_g_ShipEngines_Spec.json":Format(Ship:Name:Replace(" ","_"))).