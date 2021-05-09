@lazyGlobal off.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtPe is 2500000,
          tgtAp is 2500000,
          tgtArgPe is ship:orbit:argumentofperiapsis.

// runPath("0:/util/rck", "dvNeeded").
// runPath("0:/util/rck", "mnvTA").
// runPath("0:/util/rck", "runmode").

clearScreen.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Check for the first argument to be a lex
if tgtPe:typename = "list"
{
    local tgtParam to tgtPe.
    set tgtPe to tgtParam[0].
    set tgtAp to tgtParam[1].
    set tgtArgPe to tgtParam[2].
}

// Variables
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
local sVal          to lookDirUp(ship:prograde:vector, sun:position).
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
disp_msg("Calculating burn data").

if not util_peek_cache("dvNeeded")
{
    if raiseAp and raisePe 
    {
        print "yes rAp and yes rPe" at (2, 25).
        set xfrAp    to tgtAp.
        set compMode to "ap".
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to 0.
    }
    else if raiseAp and not raisePe 
    {
        print "yes rAp and not rPe" at (2, 25).
        set xfrAp    to tgtAp.
        set compMode to "ap".
        set tgtVal_0 to tgtAp.
        set tgtVal_1 to tgtPe.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[0], dvNeeded[1]).
        set mnvTA to 0.
    }
    else if not raiseAp and raisePe
    {
        print "not rAp and yes rPe" at (2, 25).
        set xfrAp    to stAp.
        set compMode to "pe".
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stPe, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(-dvNeeded[2], dvNeeded[1]).
        set mnvTA to 180.
    }
    else if not raiseAp and not raisePe
    {
        print "not rAp and not rPe" at (2, 25).
        set xfrAp    to stAp.
        set compMode to "pe".
        set tgtVal_0 to tgtPe.
        set tgtVal_1 to tgtAp.
        set dvNeeded to mnv_dv_bi_elliptic(stPe, stPe, tgtPe, tgtAp, xfrAp, ship:body).
        set dvNeeded to list(dvNeeded[1], -dvNeeded[2]).
        set mnvTA to 180.
    }
    util_cache_state("dvNeeded", dvNeeded).
}
else set dvNeeded to util_read_cache("dvNeeded").

disp_msg("dv0: " + round(dvNeeded[0], 2) + "  |  dv1: " + round(dvNeeded[1], 2)).
wait 5.
disp_msg().

if util_init_runmode() = 0 
{
    // Transfer burn
    disp_msg("Transfer Burn").
    set mnvTime to time:seconds + nav_eta_to_ta(ship:orbit, mnvTA).
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[0]).
    set mnvNode to mnv_opt_simple_node(mnvNode, tgtVal_0, compMode).
    add mnvNode.

    mnv_exec_node_burn(mnvNode).
    util_set_runmode(1).
    util_cache_state("mnvTA", mod(mnvTA + 180, 360)).
}

if util_init_runmode() = 1
{
    // Arrival burn
    disp_msg("Arrival Burn").
    if util_peek_cache("mnvTA") {
        set mnvTA to util_read_cache("mnvTA").
    }
    else
    {
        set mnvTA to mod(mnvTA + 180, 360).
    }
    set mnvEta      to nav_eta_to_ta(ship:orbit, mnvTA).
    set mnvTime     to time:seconds + mnvEta.
    local mnvNode   to node(mnvTime, 0, 0, dvNeeded[1]).
    set mnvNode to mnv_opt_simple_node(mnvNode, tgtVal_1, compMode).
    add mnvNode.
    mnv_exec_node_burn(mnvNode).
    util_set_runmode().
}

// Cleanup the state file
util_clear_cache_key("runmode").
util_clear_cache_key("dvNeeded").
util_clear_cache_key("mnvTA").