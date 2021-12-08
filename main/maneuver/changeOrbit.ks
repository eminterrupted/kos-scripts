@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local tgtPe to 0.
local tgtAp to 0.
local argPe to ship:orbit:argumentofperiapsis.
local orientation to "pro-sun".
local resetState to false.

if params:length > 0 
{
    set tgtPe to params[0].
    if params:length > 1 set tgtAp to params[1].
    if params:length > 2 set argPe to params[2].
    if params:length > 3 set orientation to params[3].
    if params:length > 4 set resetState to params[4].
}

// Old code below
// #region

// Variables
local cacheValues   to list("compMode", "dvNeeded", "mnvTA", "runmode", "stVal_0", "stVal_1", "tgtVal_0", "tgtVal_1").
local compMode      to "".
local doneFlag      to false.
local dvNeeded      to list().
local mnvEta        to 0.
local mnvNode       to node(0, 0, 0, 0).
local mnvTA         to 0.
local mnvTime       to time:seconds + ETAtoTA(ship:orbit, argPe).
local stAp          to ship:apoapsis.
local stPe          to ship:periapsis.

local raisePe to choose true if tgtPe >= ship:periapsis else false.
local raiseAp to choose true if tgtAp >= ship:apoapsis else false.

local stVal_0  to 0.
local stVal_1  to 0.
local tgtVal_0 to 0.
local tgtVal_1 to 0.

local xfrAp to choose tgtAp if tgtAp >= ship:apoapsis else ship:apoapsis.

// Control locks
local sVal          to GetSteeringDir(orientation).
local tVal          to 0.
lock  steering      to sVal.
lock  throttle      to tVal.

// Staging trigger
ArmAutoStaging().

if resetState PurgeCache().

// Main
if InitRunmode() = 0
{
    for val in cacheValues 
    {
        ClearCacheKey(val).
    }
    
    OutMsg("Calculating burn data").
    if raiseAp and raisePe 
    {
        print "raise rAp and raise rPe" at (2, 25).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set stVal_0  to stAp.
        set stVal_1  to stPe.
        set stPe     to choose stPe if not CheckValRange(stPe, tgtVal_0 - (tgtVal_0 * 0.01), tgtVal_0 + (tgtVal_0 * 0.01)) else stAp.
        set stAp     to choose stAp if not CheckValRange(stAp, tgtVal_1 - (tgtVal_1 * 0.01), tgtVal_1 + (tgtVal_1 * 0.01)) else stPe.
        set xfrAp    to tgtAp.
        set compMode to "ap".
        set dvNeeded to CalcDvHoh2(stPe, stAp, tgtPe, tgtAp, ship:body, compMode).
        //set dvNeeded to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body, compMode).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to mod((360 + argPe) - ship:orbit:argumentofperiapsis, 360).
    }
    else if raiseAp and not raisePe 
    {
        print "raise rAp and lower rPe" at (2, 25).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set stVal_0  to stAp.
        set stVal_1  to stPe.
        set stPe     to choose stPe if not CheckValRange(stPe, tgtVal_1 - (tgtVal_1 * 0.01), tgtVal_1 + (tgtVal_1 * 0.01)) else stAp.
        set stAp     to choose stAp if not CheckValRange(stPe, tgtVal_0 - (tgtVal_0 * 0.01), tgtVal_0 + (tgtVal_0 * 0.01)) else stPe.
        set xfrAp    to tgtAp.
        set compMode to "ap".
        set dvNeeded to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body, compMode).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to mod((360 + argPe) - ship:orbit:argumentofperiapsis, 360).
    }
    else if not raiseAp and raisePe
    {
        print "lower rAp and raise rPe" at (2, 25).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set stVal_0  to stPe.
        set stVal_1  to stAp.
        set stPe     to choose stPe if not CheckValRange(stPe, tgtVal_0 - (tgtVal_0 * 0.01), tgtVal_0 + (tgtVal_0 * 0.01)) else stAp.
        set stAp     to choose stAp if not CheckValRange(stPe, tgtVal_1 - (tgtVal_1 * 0.01), tgtVal_1 + (tgtVal_1 * 0.01)) else stPe.
        set xfrAp    to stAp.
        set compMode to "pe".
        set dvNeeded to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body, compMode).
        set dvNeeded to list(dvNeeded[1], -dvNeeded[2]).
        set mnvTA to mod((540 + argPe) - ship:orbit:argumentOfPeriapsis, 360).
    }
    else if not raiseAp and not raisePe
    {
        print "lower rAp and lower rPe" at (2, 25).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set stVal_0  to stPe.
        set stVal_1  to stAp.
        set xfrAp    to stAp.
        set compMode to "pe".
        set mnvTA to mod((360 + argPe) - ship:orbit:argumentOfPeriapsis, 360).
        set dvNeeded to CalcDvHoh(stPe, stAp, tgtPe, ship:body, compMode).
        //set dvNeeded to CalcDvHoh2(stPe, stAp, tgtPe, tgtAp, ship:body, mnvTA).
        set dvNeeded to list(dvNeeded[0], -dvNeeded[1]).
    }

    // Write to cache
    CacheState("compMode", compMode).
    CacheState("dvNeeded", dvNeeded).
    CacheState("mnvTA", mnvTA).
    CacheState("stVal_0", stVal_0).
    CacheState("stVal_1", stVal_1).
    CacheState("tgtVal_0", tgtVal_0).
    CacheState("tgtVal_1", tgtVal_1).
    OutMsg("dv0: " + round(dvNeeded[0], 2) + "  |  dv1: " + round(dvNeeded[1], 2)).

    SetRunmode(2).
}

// Read values from state file
set compMode    to ReadCache("compMode").
set dvNeeded    to ReadCache("dvNeeded").
set mnvTA       to ReadCache("mnvTA").
set stVal_0     to ReadCache("stVal_0").
set stVal_1     to ReadCache("stVal_1").
set tgtVal_0    to ReadCache("tgtVal_0").
set tgtVal_1    to ReadCache("tgtVal_1").

// print "compMode: " + compMode at (2, 30).
// print "mvnTA   : " + mnvTA AT (2, 31).
// print "stVal_0 : " + stVal_0 at (2, 32).
// print "stVal_1 : " + stVal_1 at (2, 33).
// print "tgtVal_0: " + tgtVal_0 at (2, 34).
// print "tgtVal_1: " + tgtVal_1 at (2, 35).
// print "runmode : " + ReadCache("runmode") at (2, 36).

// Transfer burn
until doneFlag
{
    if InitRunmode() = 2
    {
        if CheckValRange(stVal_0, tgtVal_0 - (tgtVal_0 * 0.01), tgtVal_0 + (tgtVal_0 * 0.01))
        {
            OutMsg("Skipping Transfer Burn").
            set mnvTA to mod(mnvTA + 180, 360).
            CacheState("mnvTA", mnvTA). 
            SetRunmode(6).
        }
        else
        {
            OutMsg("Transfer Burn").
            set mnvTA       to ReadCache("mnvTA").
            set mnvTime     to time:seconds + ETAtoTA(ship:orbit, mnvTA).
            set mnvNode   to node(mnvTime, 0, 0, dvNeeded[0]).
            add mnvNode.

            SetRunmode(4).
        }
    }

    if InitRunmode() = 4
    {
        if not hasNode 
        {
            SetRunmode(2).
        }
        else
        {
            set mnvNode to nextNode.
            if mnvNode:burnvector:mag > 0.1 
            {
                ExecNodeBurn(mnvNode).
            }
            else
            {
                remove mnvNode.
            }
            if compMode = "ap" 
            {
                CacheState("mnvTA", 180).
            }
            else
            {
                CacheState("mnvTA", 0).
            }
            SetRunmode(6).
        }
    }

    // Arrival burn
    if InitRunmode() = 6
    {
        OutMsg("Arrival Burn").
        set mnvTA       to ReadCache("mnvTA").
        set mnvEta      to ETAtoTA(ship:orbit, mnvTA).
        set mnvTime     to time:seconds + mnvEta.
        set mnvNode   to node(mnvTime, 0, 0, dvNeeded[1]).
        add mnvNode.
        OutInfo("Arrival dV: " + round(mnvNode:deltav:mag, 1)).
        SetRunmode(8).
    }

    if InitRunmode() = 8
    {
        if not hasNode
        {
            SetRunmode(6).
        }
        else
        {
            set mnvNode to nextNode.
            if mnvNode:burnVector:mag > 0.1
            {
                ExecNodeBurn(mnvNode).
            }
            else
            {
                remove mnvNode.
            }
            SetRunmode(10).
            set doneFlag to true.
        }
    }
}

// Cleanup the state file
for val in cacheValues 
{
    ClearCacheKey(val).
}
// #endregion
// End old code

OutMsg("changeOrbit complete!").