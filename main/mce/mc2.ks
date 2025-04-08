@lazyGlobal off.
clearScreen.

runOncePath("0:/kslib/lib_loader").
runOncePath("0:/lib/plan").
runOncePath("0:/lib/control").

local hdgpit to compass_and_pitch_for().
local launchAng to hdgpit[1].
local launchHdg to hdgpit[0].

// Get the plan
local mpType to "".
local mp to parse_core_plan(core).
local stgLim to 0.

// Get proper plan name
from { local i to 0. local doneFlag to false.} until i = __coreTagRef:Regex:Cat:Values:Length or doneFlag step { set i to i + 1.} do 
{
    local regex to __coreTagRef:Regex:Cat:Values[i].
    if mp:Cat:MatchesPattern(regex)
    {
        set mpType to __coreTagRef:Regex:Cat:Keys[i].
        set doneFlag to true.
    }
}

// Parse the plan
local mp to parse_core_plan(core).
if mp:Param:Length > 0
{
    set launchHdg to mp:Param[0].
    if mp:Param:Length >1 set launchAng to mp:Param[1].
}
if mp:StgLim:Length > 0
{
    set stgLim to mp:StgLim.
}

// Execute the plan
if mpType = "sdr"
{
    runPath("0:/main/launch/sounderLaunch.ks", list(launchHdg, launchAng, stgLim)).
} 
else if mpType:MatchesPattern("(^drgr$|^subo$)")
{
    runPath("0:/main/launch/downrangerLaunch.ks", list(stgLim, launchHdg, launchAng)).
}