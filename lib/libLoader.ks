// This loader, well, loads stuff. 
// Specifically the libraries, and in a specific order

// Parameters can choose individual libs to load

RunOncePath("0:/lib/globals.ks").
RunOncePath("0:/lib/util.ks").
RunOncePath("0:/kslib/lib_navball.ks").
RunOncePath("0:/kslib/lib_navigation.ks").
RunOncePath("0:/lib/engines.ks").
RunOncePath("0:/lib/vessel.ks").
RunOncePath("0:/lib/disp.ks").
RunOncePath("0:/lib/nav.ks").
RunOncePath("0:/lib/mnv.ks").
RunOncePath("0:/lib/dvCalc.ks").

// Initiate any global objects here
set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).
if g_Debug WriteJson(g_ShipEngines_Spec, "0:/data/debug/{0}_g_ShipEngines_Spec.json":Format(Ship:Name:Replace(" ","_"))).