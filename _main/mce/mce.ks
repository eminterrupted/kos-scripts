// #TODO:Parse the plan

runOncePath("0:/_kslib/lib_loader").
runOncePath("0:/_lib/plan").
runOncePath("0:/_lib/control").

local hdgpit to compass_and_pitch_for().
local launchAng to hdgpit[1].
local launchHdg to hdgpit[0].
local stgLim to 0.

// Get the plan
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

if mp:Cat:MatchesPattern("(Sounder|Sounding)")
{
    runPath("0:/_main/launch/sounderLaunch.ks", list(launchHdg, launchAng, stgLim)).
} 
else if mp:Cat:MatchesPattern("(DownRange(r)?|DR|SubDR)")
{
    runPath("0:/_main/launch/downrangerLaunch.ks", list(launchHdg, launchAng, stgLim)).
}