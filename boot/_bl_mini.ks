@lazyGlobal off.

if exists("1:/vessel.json") set Ship:Name to readJson("1:/vessel.json")[0].
sas off.
rcs off.

print "CREI-KASA BootLoader v2.0b".
print "Mission: " + Ship:Name.

local cx to false.
local commCheck to { if addons:rt:hasKscConnection(ship) return true. else return false.}.

local ts to time:seconds + 3.
until commCheck() or time:seconds > ts
{
    print "Waiting for connection to KSC...".
    if commCheck()
    {
        set cx to true.
    }
    else
    {
        wait 1.
    }
}

local lPlan to "1:/mp.json".
local aPlan to "0:/tmp/mp_" + time:seconds + ".json".
local runPlan to lPlan.

if cx
{
    runOncePath("0:/lib/loadDep").
    DispBoot().
    if ship:status = "PRELAUNCH" runPath("0:/_plan/init").
    set aPlan to "0:/_plan/" + plan + "/mp_" + missionName:Replace(" ","_") + ".json".
    set runPlan to aPlan.
    TagCores().
}

if not exists(lPlan)
{
    if commCheck() 
    {
        CopyArchivePlan(aPlan).
        set runPlan to aPlan.
    }
}

local mp to readJson(runPlan).

until mp:length = 0
{
    ClearScreen.
    
    local scr to path("0:/main/" + mp[0]).
    local param to mp[1].

    runPath(scr, param).
    mp:remove(1).
    mp:remove(0).
    writeJson(mp, lPlan).
    if commCheck() writeJson(mp, aPlan).
}

set Core:BootFileName to "".
deletePath("1:/boot").
if commCheck() deletePath(aPlan).
ClearScreen.
print "Mission plan complete!".