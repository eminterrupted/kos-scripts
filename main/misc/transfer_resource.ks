@lazyGlobal off.
clearScreen.

parameter res,
          srcElement,
          tgtElement,
          amt is -1.

runOncePath("0:/lib/lib_disp").

local srcParts to list().
local srcRes to -1.
local srcResFill to 0.
local srcResFinal to 0.
local srcValid to false.
local tgtParts to list().
local tgtRes to -1.
local tgtResFill to 0.
local tgtResFinal to 0.
local tgtValid to false.

disp_main(scriptPath()).
disp_msg("Creating transfer object").

for r in srcElement:resources 
{
    if r:name = res
    {
        set srcParts to r:parts.
        lock srcRes to r:amount.
        lock srcResFill to r:amount / r:capacity.
        set srcResFinal to srcRes - amt.
        set srcValid to true.
    }
}

if not srcValid
{
    disp_msg("ERROR: Source does not have resource!").
    print 1 / 0.
}

for r in tgtElement:resources
{
    if r:name = res
    {
        set tgtParts to r:parts.
        lock tgtRes to r:amount.
        lock tgtResFill to r:amount / r:capacity.
        set tgtResFinal to tgtRes + amt.
        set tgtValid to true.
    }
}

if not tgtValid
{
    disp_msg("ERROR: Target does not have resource capacity!").
    print 1 / 0.
}

local resTransfer to "".

if amt < 0 
{
    set resTransfer to transferAll(res, srcParts, tgtParts).
}
else
{
    set resTransfer to transfer(res, srcParts, tgtParts, amt).
}

disp_msg("Transferring resource: " + res).


set resTransfer:active to true.
wait 1. 
until resTransfer:status <> "Transferring" or srcRes <= srcResFinal or tgtRes >= tgtResFinal
{
    disp_res_transfer(res, srcElement, tgtElement, amt, srcRes, srcResFill, tgtRes, tgtResFill).
    disp_info("Status: " + resTransfer:status).
}
disp_info().
disp_msg("Transfer complete with status result: " + resTransfer:status).
set resTransfer:active to false.