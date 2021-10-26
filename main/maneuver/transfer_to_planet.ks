@lazyGlobal off.
clearScreen.

parameter stBody is ship:body,
          tgtBody is "Mun",
          tgtAlt  is 25000.

// Dependencies
local libs to list(
    "0:/lib/lib_disp.ks"               //#include "0:/lib/lib_disp"
    ,"0:/lib/lib_conics.ks"            //#include "0:/lib/lib_conics"
    ,"0:/lib/lib_mnv.ks"               //#include "0:/lib/lib_mnv"
    ,"0:/lib/lib_mnv_optimization.ks"  //#include "0:/lib/lib_mnv_optimization"
    ,"0:/lib/lib_nav.ks"               //#include "0:/lib/lib_nav"
    ,"0:/lib/lib_rendezvous.ks"        //#include "0:/lib/lib_rendezvous"
    ,"0:/lib/lib_util.ks"              //#include "0:/lib/lib_util"
    ,"0:/lib/lib_vessel.ks"            //#include "0:/lib/lib_vessel"
).

for lib in libs 
{
    local locLib to copyLocal(lib).
    runOnceLocal(locLib).
}

// Set the target
if not hasTarget set target to nav_orbitable(tgtBody).

disp_main(scriptPath()).

local runmode to util_init_runmode().

// Variables
local angVelPhase   to 0.
local angVelSt      to 0.
local angVelTgt     to 0.
local burnEta       to 0.
local dvCirc        to list().
local dvExit        to list().
local dvTrans       to list().
local mnvExit       to node(0, 0, 0, 0).
local mnvCirc       to node(0, 0, 0, 0).
local mnvInc        to node(0, 0, 0, 0).
local mnvTrans      to node(0 ,0, 0, 0).
local mnvCircTime   to 0.
local mnvExitTime   to 0.
local mnvIncTime    to 0.
local mnvTransTime  to 0.
local mnvObt        to ship:orbit.
local transferAlt   to 0.
local transferPhase to 0.
local tgtBodyAlt    to target:altitude - target:body:radius.
local tgtAltHigh    to choose true if target:altitude > stBody:altitude else false.

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

// Below this line is the "proper" way to find the transfer time. 
// However, since we will be using a 4 step method of exit, circ, 
// match inc, transfer, we need to exit immediately vs some arbitrary
// point in the future

// // Calculate ideal phase angle between stBody and tgtBody around kerbol
// lock currentPhase to mod(360 + ksnav_phase_angle(target, stBody), 360).
// local transferPhase to nav_transfer_phase_angle(target, stBody:orbit:semimajoraxis).
// // Turn phase angle into transfer window

// disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").

//     // Calulate the timestamp to burn from the start body
//     local angVelSt      to nav_ang_velocity(stBody, stBody:body).
//     local angVelTgt     to nav_ang_velocity(target, target:body).
//     local angVelPhase   to angVelSt - angVelTgt.
//     set burnEta         to (currentPhase - transferPhase) / angVelPhase.
//     if burnEta < 0 
//     {
//         set burnEta to burnEta + ship:orbit:period.
//     }
//     set mnvExitTime     to burnEta + time:seconds.

//     print "Target           : " + target + "   " at (2, 23).
    
//     print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
//     print "Time to transfer : " + round(burnEta) at (2, 25).
    
//     disp_msg().
//     disp_info().

    // Get the amount of DV required for exit velocity
    // set dvExit to mnv_dv_interplanetary_departure(stBody, target, ship:orbit:semiMajorAxis, tgtAlt + target:radius).
    // print "Transfer dV      : " + round(dvExit[0], 2) + "m/s     " at (2, 27).
    // print "Arrival  dV      : " + round(dvExit[1], 2) + "m/s     " at (2, 28).

    // // Add the exit maneuver node
    // set mnvExit to node(mnvExitTime, 0, 0, dvExit[0]).
    // add mnvExit.
    // wait 0.25.

if runmode = 0 
{
    if tgtAltHigh
    {
        set mnvExit to mnv_exit_node(stBody:body, "pro").
        set transferAlt to stBody:altitude + ((target:altitude - stBody:altitude) / 8).
        set mnvExit to mnv_optimize_exit_ap(mnvExit, transferAlt).
        set mnvExit to mnv_opt_simple_node(mnvExit, transferAlt, "ap", stBody:body).
    }
    else
    {
        set mnvExit to mnv_exit_node(stBody:body, "retro").
        set transferAlt to target:altitude + (stBody:altitude / 20).
        set mnvExit to mnv_optimize_exit_pe(mnvExit, transferAlt).
        set mnvExit to mnv_opt_simple_node(mnvExit, transferAlt, "pe", stBody:body).
    }
    add mnvExit.
    wait 1.

    // Inclination matching
    set mnvObt to nav_next_patch_for_node(mnvExit).
    set mnvInc    to mnv_inc_match_burn(ship, mnvObt, target:orbit)[2].
    set mnvIncTime to mnvInc:time. 
    add mnvInc.
    wait 1.

    // Add the circ node
    set mnvObt to nav_next_patch_for_node(mnvInc).
    set mnvCircTime to choose time:seconds + mnvObt:eta:apoapsis if tgtAltHigh else time:seconds + mnvObt:eta:periapsis.
    
    // Get the dv and create a node for the circularization burn
    set dvCirc to mnv_dv_bi_elliptic(mnvObt:periapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:apoapsis, mnvObt:body).
    set mnvCirc to choose node(mnvCircTime, 0, 0, dvCirc[1]) if tgtAltHigh else node(mnvCircTime, 0, 0, -dvCirc[0]).
    add mnvCirc.
    wait 1.

    set runmode to util_set_runmode(5).
}

// We are now ready to execute these nodes prior to setting up the final transfer node to target
if runmode = 5
{
    mnv_exec_node_burn(nextNode).
    set runmode to util_set_runmode(10).
}

if runmode = 10
{
    mnv_exec_node_burn(nextNode).
    set runmode to util_set_runmode(15).
}

if runmode = 15
{
    mnv_exec_node_burn(nextNode).
    set runmode to util_set_runmode(20).
}

if runmode = 20
{
    // Now perform the final transfer
    lock currentPhase to mod(360 + ksnav_phase_angle(), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to nav_transfer_phase_angle(target, ship:orbit:semimajoraxis - ship:body:radius).

    disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").

    // Calulate the transfer timestamp
    set angVelSt      to nav_ang_velocity(ship, target:body).
    set angVelTgt     to nav_ang_velocity(target, target:body).
    set angVelPhase   to angVelSt - angVelTgt.
    set burnEta       to (currentPhase - transferPhase) / angVelPhase.
    if burnEta < 0
    {
        set burnEta to burnEta + ship:orbit:period.
    }
    set mnvTransTime  to burnEta + time:seconds.

    print "Target           : " + target + "   " at (2, 23).
    
    print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
    print "Time to transfer : " + round(burnEta) at (2, 25).
    
    disp_msg().
    disp_info().

    // Get the amount of dv needed to get to the target
    set dvTrans to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtBodyAlt, tgtBodyAlt, tgtBodyAlt).
    print "Transfer dV      : " + round(dvTrans[0], 2) + "m/s     " at (2, 27).
    print "Arrival  dV      : " + round(dvTrans[1], 2) + "m/s     " at (2, 28).

    // Add the maneuver node
    set mnvTrans to mnv_opt_transfer_node(node(mnvTransTime, 0, 0, dvTrans[0]), target, tgtAlt, 0.01).
    add mnvTrans.

    mnv_exec_node_burn(nextNode).
    util_clear_cache_key("runmode").
}



// Local Functions

// function for copying libs to data disk
local function copyLocal
{
    parameter srcFile.

    local destFile to changeRoot(srcFile, "data_0").
   
    if addons:rt:hasKscConnection(ship) 
    {
        if exists(srcFile) copyPath(srcFile, destFile).
    }
    return destFile.
}

// function for running libs off data disk. If not found, or if a KSC connection is available, run from archive
local function runOnceLocal
{
    parameter fileToRun.

    if not exists(fileToRun) and addons:rt:hasKscConnection(ship)
    {
        set fileToRun to changeRoot(fileToRun, "0").
    }
    runOncePath(fileToRun).
}

// Change the root of a path
local function changeRoot
{
    parameter srcFile,
              destRoot.

    if srcFile:typename = "string" set srcFile to path(srcFile).
    
    local   destFile to destRoot + ":".
    local   srcSeg   to srcFile:segments.

    from { local idx to 0.} until idx >= srcSeg:length step {set idx to idx + 1.} do {
        set destFile to destFile + "/" + srcSeg[idx].
    }
    return path(destFile).
}