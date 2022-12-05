
@LazyGlobal off.

// Load Dependencies
RunOncePath("0:/lib/loadDep").

// Tag parsing
set g_tag to ParseCoreTag().

// Detect if we are pre-launch, and if so, set up the mission plan. 
if ship:status = "PRELAUNCH"
{
    runPath("0:/setup/mpSetup.ks").
}
// Detect that we have a valid mission plan
if exists(Path(g_missionPlan))
{
    // TODO: Execute Mission Plan with more flair
    runPath(Path(g_missionPlan), g_Tag:PRM).
}

// TODO: Mission plan statistics