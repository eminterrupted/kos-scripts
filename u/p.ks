@lazyGlobal off.

parameter _tgt is target:name.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_rendezvous").

local incChangeScript to "0:/a/simple_inclination_change".
local mnvNode to node(0, 0, 0, 0).
local mnvObj to lex().
local runmode to stateObj["runmode"].
local trnsfrAlt to 100.
local tStamp to 0.

local sVal to lookDirUp(ship:prograde:vector, sun:position).
local tVal to 0.

lock steering to sVal.
lock throttle to tVal.

if not hasTarget set target to orbitable(_tgt).

// Main
if runmode = 0 
{
    out_msg("Checking inclination").
    if ship:orbit:inclination < target:orbit:inclination - 0.1 or ship:orbit:inclination > target:orbit:inclination + 0.1 
    {
        out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + target:obt:inclination + "]").
        runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
    }
    set runmode to rm(5).
}

if runmode = 5 
{
    out_msg("Getting transfer object and adding node").
    set mnvObj to get_transfer_obj().
    set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
    add mnvNode. 
    set runmode to rm(10).
}

if runmode = 10 
{
    if not hasNode 
    {
        set runmode to rm(5).
    } else 
    {
        set mnvObj to get_burn_obj_from_node(nextNode).
        set runmode to rm(15).
    }
}

//Warps to the burn node
if runmode = 15 
{
    out_msg("Warping to burn node").
    warp_to_timestamp(mnvObj["burnEta"]).
    set runmode to rm(20).
}

// //Executes the transfer burn
// if runmode = 35 
// {
//     out_msg("Executing burn node").
//     exec_node(nextNode).
//     set runmode to rm(37).
// }