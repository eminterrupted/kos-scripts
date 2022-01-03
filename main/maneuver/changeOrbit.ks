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

DispMain(scriptPath(), false).

local tgtPe to 0.
local tgtAp to 0.
local argPe to Ship:Orbit:ArgumentOfPeriapsis.
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
// local comp_0        to "".
// local comp_1        to "".
local compMode      to "".
local doneFlag      to false.
local dv1           to 0.
local dv2           to 0.
local dvNeeded      to list().
local mnvEta        to 0.
local mnvNode       to node(0, 0, 0, 0).
local mnvTA         to 0.
local mnvTime       to Time:Seconds + ETAtoTA(Ship:Orbit, argPe).
local stAp          to Ship:Apoapsis.
local stPe          to Ship:Periapsis.

local raisePe to choose true if tgtPe >= Ship:Periapsis else false.
local raiseAp to choose true if tgtAp >= Ship:Apoapsis else false.

// local stVal_0  to 0.
// local stVal_1  to 0.
local tgtVal_0 to 0.
local tgtVal_1 to 0.

local xfrAlt to choose tgtAp if tgtAp >= Ship:Apoapsis else Ship:Apoapsis.

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
        set mnvTA to mod((360 + argPe) - Ship:Orbit:ArgumentOfPeriapsis, 360).
        set stPe     to AltAtTA(ship:orbit, mnvTA).
        set stAp     to AltAtTA(ship:orbit, mnvTA + 180).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set compMode to "ap".
        set xfrAlt   to choose tgtAp if compMode = "ap" else tgtPe.
        set dv1 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "ap")[0].
        set dv2 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "pe")[1].
        set dvNeeded to list(dv1, dv2).
    }
    else if raiseAp and not raisePe 
    {
        print "raise rAp and lower rPe" at (2, 25).
        set mnvTA to mod((360 + argPe) - Ship:Orbit:ArgumentOfPeriapsis, 360).
        set stPe     to AltAtTA(ship:orbit, mnvTA).
        set stAp     to AltAtTA(ship:orbit, mnvTA + 180).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set compMode to "ap".
        set xfrAlt   to tgtAp.
        set dv1 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "ap")[0].
        set dv2 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "pe")[1].
        set dvNeeded to list(dv1, dv2).
    }
    else if not raiseAp and raisePe
    {
        print "lower rAp and raise rPe" at (2, 25).
        set mnvTA to mod((360 + argPe) - Ship:Orbit:argumentOfPeriapsis, 360).
        set stPe     to AltAtTA(ship:orbit, mnvTA + 180).
        set stAp     to AltAtTA(ship:orbit, mnvTA).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set compMode to "ap".
        set xfrAlt   to tgtAp. // choose tgtAp if compMode = "ap" else tgtPe.
        set dv1 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "pe")[1].
        set dv2 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "ap")[0].
        set dvNeeded to list(dv1, dv2).
    }
    ///THIS ONE vvvvv
    else if not raiseAp and not raisePe
    {
        print "lower rAp and lower rPe" at (2, 25).
        set mnvTA    to mod((540 + argPe) - Ship:Orbit:argumentOfPeriapsis, 360).
        set stPe     to AltAtTA(ship:orbit, mnvTA).
        set stAp     to AltAtTA(ship:orbit, mnvTA + 180).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set compMode to "pe".
        set xfrAlt   to tgtPe. // choose tgtAp if compMode = "ap" else tgtPe.
        set dv1 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "pe")[0].
        set dv2 to CalcDvBE(stPe, stAp, tgtPe, tgtAp, xfrAlt, Ship:Body, "ap")[1].
        set dvNeeded to list(dv1, dv2).
    }

    // Write to cache
    CacheState("compMode", compMode).
    CacheState("dvNeeded", dvNeeded).
    CacheState("mnvTA", mnvTA).
    SetRunmode(2).
}

// Read values from state file
set compMode    to ReadCache("compMode").
set dvNeeded    to ReadCache("dvNeeded").
set mnvTA       to ReadCache("mnvTA").

print "dv1     : " + round(dvNeeded[0], 3) at (2, 27).
print "dv2     : " + round(dvNeeded[1], 3) at (2, 28).
print "tgtVal_0: " + tgtVal_0 at (2, 30).
print "tgtVal_1: " + tgtVal_1 at (2, 31).
print "mvnTA   : " + mnvTA AT (2, 32).
print "compMode: " + compMode at (2, 33).
print "runmode : " + ReadCache("runmode") at (2, 35).

// Transfer burn
until doneFlag
{
    if InitRunmode() = 2
    {
        if CheckValRange(dvNeeded[0], -0.2, 0.2)
        {
            OutMsg("Skipping Transfer Burn").
            set mnvTA to mod(mnvTA + 180, 360).
            CacheState("mnvTA", mnvTA). 
            OutInfo("dvNeeded: " + dvNeeded[0]).

            SetRunmode(6).
        }
        else
        {
            OutMsg("Transfer Burn").
            set mnvTA       to ReadCache("mnvTA").
            set mnvTime     to Time:Seconds + ETAtoTA(Ship:Orbit, mnvTA).
            set mnvNode   to node(mnvTime, 0, 0, dvNeeded[0]).
            add mnvNode.

            SetRunmode(4).
        }
    }

    else if InitRunmode() = 4
    {
        if not hasNode 
        {
            SetRunmode(2).
        }
        else
        {
            set mnvNode to nextNode.
            if mnvNode:BurnVector:Mag > 0.1 
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
    else if InitRunmode() = 6
    {
        if CheckValRange(dvNeeded[1], -0.2, 0.2)
        {
            outMsg("Skipping arrival burn").
            OutInfo("dvNeeded: " + dvNeeded[1]).

            SetRunmode(10).
        }
        else
        {
            OutMsg("Arrival Burn").
            set mnvTA       to ReadCache("mnvTA").
            set mnvEta      to ETAtoTA(Ship:Orbit, mnvTA).
            set mnvTime     to Time:Seconds + mnvEta.
            set mnvNode   to node(mnvTime, 0, 0, dvNeeded[1]).
            add mnvNode.
            OutInfo("Arrival dV: " + round(mnvNode:BurnVector:Mag, 1)).

            SetRunmode(8).
        }
    }

    else if InitRunmode() = 8
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
        }
    }

    else if InitRunmode() = 10
    {
        set doneFlag to true.
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