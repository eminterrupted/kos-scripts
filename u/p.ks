@lazyGlobal off.

parameter _tgt is target:name.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_node").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_rendezvous").

local incChangeScript to "0:/a/simple_inclination_change".
local rdvScript to "0:/a/rendezvous_next".

local mnvNode to node(0, 0, 0, 0).
local mnvObj to lex().
local runmode to init_rm().

local sVal to lookDirUp(ship:prograde:vector, sun:position).
local tVal to 0.

lock steering to sVal.
lock throttle to tVal.

if _tgt:typename = "string" set _tgt to orbitable(_tgt).
if not hasTarget set target to _tgt.

// Main
if runmode = 0
{
    for m in allNodes
    {
        remove m.
    }
    set runmode to rm(5).
}

if runmode = 5 
{
    out_msg("Checking inclination").
    if ship:orbit:inclination < target:orbit:inclination - 0.1 or ship:orbit:inclination > target:orbit:inclination + 0.1 
    {
        out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + target:obt:inclination + "]").
        runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
    }
    else
    {
        out_msg("Inclination within range").
    }
    set runmode to rm(10).
}

if runmode = 10
{
    out_msg("Getting transfer object and adding node").
    set mnvObj to get_transfer_obj().
    set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
    add mnvNode. 
    set mnvNode to optimize_rendezvous_node(mnvNode).
    set mnvObj to get_burn_obj_from_node(nextNode).

    lock steering to mnvNode:burnVector. 
    wait until shipFacing().
    
    set runmode to rm(15).
    breakpoint().
}

//Warps to the burn node
if runmode = 15 
{
    out_msg("Warping to burn node").
    warp_to_timestamp(mnvObj["burnEta"]).
    until time:seconds >= mnvObj["burnEta"]
    {
        update_display().
        disp_burn_data(mnvObj["burnEta"]).
    }
    disp_clear_block("burn_data").
    set runmode to rm(20).
}

//Executes the transfer burn
if runmode = 20 
{
    out_msg("Executing burn node").
    exec_node(nextNode).
    set runmode to rm(25).
}

//Runs the rendezvous loop.
if runmode = 25
{
    out_msg("Executing rendezvous script").
    runPath(rdvScript, _tgt).
    set runmode to rm(30).
}

if runmode = 30
{
    out_msg("Ending script").
    set runmode to rm(0).
}