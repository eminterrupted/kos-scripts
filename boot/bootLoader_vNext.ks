@lazyGlobal off.
clearScreen.

bl_init_disk().
if missionTime = 0
{
    runPath("0:/main/controller/newController").
}
local mc to "local:/missionController".
runPath(mc).

//-- Functions --//
local function bl_init_disk
{
    local cores to ship:modulesNamed("kOSProcessor").
    local idx   to 0.
    
    set core:volume:name to "local".
    for c in cores
    {
        if c:volume:name = "" set c:volume:name to "data_" + idx.
        set idx to idx + 1.
    }
}