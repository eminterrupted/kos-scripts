@lazyGlobal off.
clearScreen.

local amc to path("0:/main/controller/missionController").
local lmc to path("1:/" + amc:name).
local mc to "".

until false
{
    if addons:rt:hasKscConnection(ship)
    {
        if exists(lmc) deletePath(lmc).
        copyPath(amc, lmc).
        set mc to choose lmc if exists(lmc) else amc.
        break.
    }
    else if exists(lmc)
    {
        set mc to lmc.
        break.
    }
    else
    {
        wait_for_ksc().
    }
}
clearScreen.
runPath(mc).


// Waiting for a ksc connection
local function wait_for_ksc
{
    print "[INFO] Waiting for KSC connection...".
        until addons:rt:hasKscConnection(ship)
        {
            wait 30.
        }
    print "[INFO]: Connection to KSC established".
}