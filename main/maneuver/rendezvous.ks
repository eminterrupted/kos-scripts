@lazyGlobal off.
clearScreen.

parameter tgtParam is "Jebsted's Derelict",
          altPadding to 100.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
//runOncePath("0:/kslib/lib_navigation").

disp_main(scriptPath()).

local runmode to util_init_runmode().

local burnAt            to 0.
local currentPhase      to 0.  
local degreesToTravel   to 0.
local dvNeeded          to 0.
local mnvBurn           to list().
local mnvNode           to node(0, 0, 0, 0).
local phaseRate         to 0.
local tgtAlt            to 0.
local transferEta       to 0.
local transferPhase     to 0.

local tgtObt to createOrbit(
    target:orbit:inclination, 
    ship:orbit:eccentricity, 
    ship:orbit:semimajoraxis, 
    target:orbit:lan, 
    target:orbit:argumentofperiapsis, 
    ship:orbit:meanAnomalyAtEpoch, 
    ship:orbit:epoch, 
    ship:body
).

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

if not hasTarget 
{
    if tgtParam:typeName = "list" set tgtParam to tgtParam[0].
    else if tgtParam:typename = "string" set tgtParam to nav_orbitable(tgtParam).
    set target to nav_orbitable(tgtParam).
}
else
{
    set tgtParam to target.
}

if runmode = 0 
{
    if not util_check_value(ship:orbit:inclination, 2.5)
    {
        disp_msg("Inc_Match with " + target:name).
        set mnvBurn to mnv_inc_match_burn(ship, tgtObt).
        set mnvNode to mnvBurn[2].
        add mnvNode.
        mnv_exec_node_burn(mnvNode).
    }

    //set runmode to util_set_runmode(5).
    set runmode to util_set_runmode(10).
}

// if runmode = 5
// {
//     if not util_check_value(ship:orbit:argumentofperiapsis, 5)
//     {
//         disp_msg("ArgPe_Match with " + target:name).
//         set mnvBurn to mnv_argpe_match_burn(ship, tgtObt).
//         set mnvNode to mnvBurn[2].
//         add mnvNode.
//         mnv_exec_node_burn(mnvNode).
//     }

//  set runmode to util_set_runmode(10).
// }

if runmode = 10
{
    set tgtAlt to target:altitude + altPadding.
    lock currentPhase to mod(ksnav_phase_angle(tgtParam), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to mod(nav_transfer_phase_angle(target, (ship:apoapsis + ship:periapsis / 2)) + 360, 360).

    disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").
    // Calculate the time we should make the transfer at
    // Sample the phase change per second
    disp_info("Sampling phase change per second").
    wait 0.01.
    local ts to time:seconds + 10.
    local ts2 to time:seconds.
    local p0 to currentPhase.
    until time:seconds >= ts 
    {
        disp_info2("Sampling time remaining: " + round(ts - time:seconds, 1)).
        print "Current Phase Rate: " + ((abs(abs(currentPhase) - abs(p0))) / (time:seconds - ts2)) at (2, 35).
        print "ts2 - time:seconds: " + (time:seconds - ts2) at (2, 36).
    }
    set phaseRate  to (abs(abs(currentPhase) - abs(p0))) / 10.
    disp_msg().
    disp_info().
    disp_info2(). 

    // Calulate the transfer timestamp
    set degreesToTravel to choose transferPhase - currentPhase if transferPhase <= currentPhase else currentPhase + (360 - transferPhase).
    set transferEta     to degreesToTravel / phaseRate.
    set burnAt            to transferEta + time:seconds.

    print "Degrees to travel: " + round(degreesToTravel, 5) at (2, 24).
    print "Phase Rate       : " + round(phaseRate, 5) at (2, 25).
    print "Time to transfer : " + round(transferEta) at (2, 26).
    print "BurnAt           : " + round(burnAt) at (2, 27).

    // Get the amount of dv needed to get to the target
    set dvNeeded to mnv_dv_hohmann(ship:altitude, tgtAlt, ship:body).
    disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

    // Add transfer burn
    set mnvNode to node(burnAt, 0, 0, dvNeeded[0]).
    add mnvNode.

    util_cache_state("dvNeeded", dvNeeded).
    set runmode to util_set_runmode(20).
}

if runmode = 20
{
    mnv_exec_node_burn(nextNode).
    set runmode to util_set_runmode(25).
}

if runmode = 25
{
    set dvNeeded to util_read_cache("dvNeeded").
    set mnvNode to node(burnAt + (ship:orbit:period / 2), 0, 0, dvNeeded[1]).
    add mnvNode.
    mnv_exec_node_burn(nextNode).
    set runmode to util_set_runmode(30).
}

if runmode = 30
{
    until false 
    {
        // Approach the target
        rdv_await_nearest_approach(target, 1250).
        rdv_approach_target(target, 1).
        rdv_cancel_velocity(target).
        if target:distance < 50 break.
    }
}