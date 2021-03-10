@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_vessel").

local sciList to sci_modules().
local tStamp  to time:seconds + 21600.

local rVal to choose 180 if ship:crew():length > 0 else 0.
local sVal to ship:prograde + r(0, 0, rVal).
lock steering to sVal.

ves_activate_solar().

disp_main().

until time:seconds >= tStamp
{
    local sciInterval to time:seconds + 5.
    until time:seconds >= sciInterval 
    {
        set sVal to ship:prograde + r(0, 0, rVal).
        disp_msg("Next science report in " + round(sciInterval - time:seconds) + "s").
        disp_orbit().
        wait 0.1.
    }
    if warp > 0 set warp to 0.
    disp_msg("Collecting crew report").
    sci_deploy_list(sciList).
    sci_recover_list(sciList).
    if terminal:input:hasChar
    {
        if terminal:input:getChar() = terminal:input:return 
        {
            break.
        }
    }
}

disp_msg("Science mission complete!").
wait 2.5.