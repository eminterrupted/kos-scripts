@LazyGlobal off.

runOncePath("0:/lib/loadDep.ks").

local setupPlan to Path("0:/_plan/{0}/setup.ks":format(g_tag["PCN"])).
local missionPlanPath to path("0:/_missions/{0}/{1}.ks":format(g_tag["PCN"], ship:name:replace(" ","_"))).

// print g_tag.
// Breakpoint().

// print "setupPlan:  [{0}]":format(setupPlan).
// print "missionPlan:[{0}]":format(missionPlanPath).

// Breakpoint().

copyPath(setupPlan, missionPlanPath).
set g_missionPlan to missionPlanPath.