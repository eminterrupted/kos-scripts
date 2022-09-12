@lazyGlobal off.
clearScreen.

parameter queryStr to "",
          setTgt to false.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/nav").

DispMain(scriptPath(), false).

local hitList to list().
local hitCount to 0.
OutMsg(("Target search term: [{0}]"):format(queryStr)).

for t in buildList("targets")
{
    if t:name:matchesPattern(queryStr)
    {
        set hitCount to hitCount + 1.
        hitList:add(t).
    }
    OutInfo("Hits: {0}":Format(hitCount)).
}

OutInfo().
if hitList:length > 0 
{
    OutMsg("Results: {0}":format(hitCount)).
    if setTgt
    {
        set Target to GetOrbitable(PromptItemSelect(hitList, "Select target", true, "tgt")).
        OutMsg("Selected target: {0}":format(Target:name)).
    }
}
else
{
    OutMsg("No targets found matching query string [{0}]":format(queryStr)).
}