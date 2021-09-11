@lazyGlobal off.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtPe is 25000,
          tgtAp is 25000,
          tgtArgPe is ship:orbit:argumentofperiapsis.

clearScreen.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).

local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.

// Check for the first argument to be a lex
if tgtPe:typename = "list"
{
    local tgtParam to tgtPe.
    set tgtPe to tgtParam[0].
    set tgtAp to tgtParam[1].
    set tgtArgPe to tgtParam[2].
}

// Variables
local cacheValues   to list("compMode", "dvNeeded", "mnvTA", "runmode", "tgtVal_0", "tgtVal_1").
local compMode      to "".
local dvNeeded      to list().
local mnvEta        to 0.
local mnvTA         to 0.
local mnvTime       to time:seconds + nav_eta_to_ta(ship:orbit, tgtArgPe).

local raisePe to choose true if tgtPe >= ship:periapsis else false.
local raiseAp to choose true if tgtAp >= ship:apoapsis else false.

local stAp to ship:apoapsis.
local stPe to ship:periapsis.

local tgtVal_0 to 0.
local tgtVal_1 to 0.

local xfrAp to choose tgtAp if tgtAp >= ship:apoapsis else ship:apoapsis.

// Control locks
local sVal          to lookDirUp(ship:facing:vector, sun:position).
local tVal          to 0.
lock  steering      to sVal.
lock  throttle      to tVal.

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
if util_init_runmode() = 0 
{
    for val in cacheValues 
    {
        util_clear_cache_key(val).
    }
    
    disp_msg("Calculating burn data").
    if raiseAp and raisePe 
    {
        print "raise rAp and raise rPe" at (2, 25).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set compMode to "ap".
        set xfrAp    to tgtAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to mod((360 + tgtArgPe) - ship:orbit:argumentofperiapsis, 360).
    }
    else if raiseAp and not raisePe 
    {
        print "raise rAp and lower rPe" at (2, 25).
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set compMode to "ap".
        set xfrAp    to tgtAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to mod((360 + tgtArgPe) - ship:orbit:argumentofperiapsis, 360).
    }
    else if not raiseAp and raisePe
    {
        print "lower rAp and raise rPe" at (2, 25).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set compMode to "pe".
        set xfrAp    to stAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stPe, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[1], -dvNeeded[2]).
        set mnvTA to mod((540 + tgtArgPe) - ship:orbit:argumentOfPeriapsis, 360).
    }
    else if not raiseAp and not raisePe
    {
        print "lower rAp and lower rPe" at (2, 25).
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set compMode to "pe".
        set xfrAp    to stAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stPe, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[1], -dvNeeded[2]).
        set mnvTA to mod((540 + tgtArgPe) - ship:orbit:argumentOfPeriapsis, 360).
    }

    // Write to cache
    util_cache_state("compMode", compMode).
    util_cache_state("dvNeeded", dvNeeded).
    util_cache_state("mnvTA", mnvTA).
    util_cache_state("tgtVal_0", tgtVal_0).
    util_cache_state("tgtVal_1", tgtVal_1).
    disp_msg("dv0: " + round(dvNeeded[0], 2) + "  |  dv1: " + round(dvNeeded[1], 2)).

    util_set_runmode(2).
}

// Read values from state file
set compMode    to util_read_cache("compMode").
set dvNeeded    to util_read_cache("dvNeeded").
set mnvTA       to util_read_cache("mnvTA").
set tgtVal_0    to util_read_cache("tgtVal_0").
set tgtVal_1    to util_read_cache("tgtVal_1").

// Transfer burn
if util_init_runmode() = 2
{
    disp_msg("Transfer Burn").
    set mnvTA       to util_read_cache("mnvTA").
    set mnvTime     to time:seconds + nav_eta_to_ta(ship:orbit, mnvTA).
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[0]).
    set mnvNode     to mnv_opt_simple_node(mnvNode, tgtVal_0, compMode).
    add mnvNode.
    if mnvNode:burnvector:mag > 0.1 
    {
        mnv_exec_node_burn(mnvNode).
    }
    else
    {
        remove mnvNode.
    }
    if compMode = "ap" 
    {
        util_cache_state("mnvTA", 180).
    }
    else
    {
        util_cache_state("mnvTA", 0).
    }
    util_set_runmode(3).
}

// Arrival burn
if util_init_runmode() = 3
{
    disp_msg("Arrival Burn").
    set mnvTA       to util_read_cache("mnvTA").
    set mnvEta      to nav_eta_to_ta(ship:orbit, mnvTA).
    set mnvTime     to time:seconds + mnvEta.
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[1]).
    wait 1.
    set mnvNode to choose mnv_opt_simple_node(mnvNode, tgtVal_1, "pe") if compMode = "ap" else mnv_opt_simple_node(mnvNode, tgtVal_1, "ap").
    add mnvNode.
    if mnvNode:burnVector:mag > 0.1
    {
        mnv_exec_node_burn(mnvNode).
    }
    else
    {
        remove mnvNode.
    }
    util_set_runmode().
}

// Cleanup the state file
for val in cacheValues 
{
    util_clear_cache_key(val).
}