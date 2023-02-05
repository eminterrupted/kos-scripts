@LazyGlobal off.

runOncePath("0:/lib/loadDep.ks").

local setupPlan to Path("0:/_plan/{0}/setup.ks":format(g_tag["PCN"])).
set g_missionPlan to path("0:/_mission/{0}/{1}.ks":format(g_tag["PCN"], ship:name:replace(" ","_"))).
set g_MP_Json to path("0:/_mission/{0}/{1}.json":Format(g_tag["PCN"], ship:name:replace(" ","_"))).
runPath(setupPlan).
// print g_tag.
// Breakpoint().

// print "setupPlan:  [{0}]":format(setupPlan).
// print "missionPlan:[{0}]":format(missionPlanPath).

// Breakpoint().

WriteJson(g_MP_List, g_MP_Json).
copyPath(setupPlan, g_missionPlan).
