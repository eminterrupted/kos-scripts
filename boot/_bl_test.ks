@lazyGlobal off.

if exists("1:/vessel.json") set Ship:Name to readJson("1:/vessel.json").
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
local arcDone to "0:/tmp/done_" + time:seconds + ".json".
local mpPath to lPlan.
local mpDone to "1:/done.json".

if cx
{
    runOncePath("0:/lib/loadDep").
    DispBoot().
    if ship:status = "PRELAUNCH" runPath("0:/_plan/init").
    set aPlan to "0:/_plan/" + plan + "/mp_" + missionName:Replace(" ","_") + ".json".
    set mpPath to aPlan.
    TagCores().
}

if not exists(lPlan)
{
    if commCheck() 
    {
        if exists(aPlan) set mpPath to aPlan.
    }
}

local mp to readJson(mpPath).
local mpIterator to mp:iterator.

ClearScreen.
until mpIterator:AtEnd and mpIterator:index >= 0
{
    mpIterator:next.
    local mission to mpIterator:value:split(";").
    print mission at (2, 15).
    wait 2.5.
    if mission:length > 1
    {
        local scr to path("0:/main/" + mission[0]).
        local params to mission[1]:split(",").

        runPath(scr, params).
        log mpIterator:index + "|" + Round(MissionTime) + scr + "|" + params:join(",") to mpDone.
    }
    else 
    {
        set mp to mp:replace(mission[0], "").
    }
    
    if commCheck() 
    {  
        copyPath(mpDone, arcDone).
    }
}

set Core:BootFileName to "".
deletePath("1:/boot").
if commCheck() deletePath(aPlan).
ClearScreen.
print "Mission plan complete!".