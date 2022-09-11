@lazyGlobal off.
clearScreen.

Parameter params is list().

runOncePath("0:/lib/loadDep").

local tgtAp to 10000.
local tgtPe to 10000.
local tgtInc to 0.
local stagedLaunch to false.
local position to 0.

local mpPath to Path("1:/mp.json").
local _mpObj to readJson(mpPath).

local planList to list(
        "maneuver/landOnBody", list(), 
        "mission/landSci", list(), 
        "launch/noAtmoAscent", list(stagedLaunch, tgtAp, tgtPe, tgtInc),
        "launch/circPhase", list()
    ).

if params:length > 0
{
    set tgtAp to params[0].
    set tgtPe to params[0].
    if params:length > 1 set tgtPe to params[1].
    if params:length > 2 set tgtInc to params[2].
    if params:length > 3 set stagedLaunch to params[3].
    if params:length > 4 set position to params[4].
}

if exists(_mpObj)
{
    if _mpObj:isType("List")
    {
    }
    else
    {
        set _mpObj to readJson(_mpObj).
    }

    from { local i to 0.} until i = planList:length step { set i to i + 1.} do 
    {
        _mpObj:insert(position + i, planList[i]).
        wait 0.01.
    }

    writeJson(_mpObj, mpPath).
    OutMsg("Landing successfully written to mp.json").
}
else
{
    writeJson(planList, mpPath).
    OutMsg("New mp.json generated with landing").
}