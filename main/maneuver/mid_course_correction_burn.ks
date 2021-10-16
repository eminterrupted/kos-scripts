@lazyGlobal off.
clearScreen.

parameter tgtParam is "Pe",
          tgtVal is 30000,
          tgtBody is body("Mun").

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_util").

local burnAt        to time:seconds + 300.
local burnDur       to 0.
local checkOrbit    to ship:orbit.
local halfDur       to 0.
local burnEta       to 0.

if tgtBody <> ship:body
{
    if ship:orbit:hasNextPatch
    {
        set checkOrbit to ship:orbit:nextPatch.
    }
    else
    {
        print "ERR: No next patch. Run transfer_to_body to fix" at (2, 10).
    }

    if tgtParam = "pe" 
    {
        if not util_check_range(checkOrbit:periapsis, tgtVal - 500, tgtVal + 500)
        {
            correction_burn().
        }
    }
    else if tgtParam = "ap"
    {
        if not util_check_range(checkOrbit:apoapsis, tgtVal - 500, tgtVal + 500)
        {
            correction_burn().
        }
    }
}

local function correction_burn
{
    disp_msg("Mid-course correction burn for " + tgtBody:name + " " + tgtParam).
    local mnvNode to mnv_opt_transfer_node(node(burnAt, 0, 0, 0), tgtBody, tgtVal, 1).
    add mnvNode.

    // Transfer burn
    set burnAt  to mnvNode:time.
    set burnDur to mnv_staged_burn_dur(mnvNode:burnVector:mag).
    set halfDur to mnv_staged_burn_dur(mnvNode:burnVector:mag / 2).
    set burnEta to burnAt - halfDur.
    disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
    disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
    mnv_exec_node_burn(mnvNode).

    if ship:orbit:hasnextpatch 
    {
        disp_msg("Transfer complete!").
        disp_info("Pe at target: " + round(ship:orbit:nextPatch:periapsis)).
    }
} 