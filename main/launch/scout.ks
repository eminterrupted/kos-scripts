@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_disp").

local sciFlag   to false.
local sciList   to sci_modules(). 

lock steering to up.

// Main
sci_deploy_list(sciList).
wait 1.
sci_recover_list(sciList).

local ts to time:seconds + 10.
until time:seconds >= ts
{
    print "Countdown: " + round(time:seconds - ts) + " " at (2, 2).
}
stage.

when ship:availablethrust <= 0.1 then
{
    stage.
}

until ship:altitude >= 18000
{
    if not sciFlag
    {
        sci_deploy_list(sciList).
        sci_recover_list(sciList).
        set sciFlag to true.
    }
    disp_telemetry().
    wait 0.05.
}

set sciFlag to false.

until ship:altitude >= 70000
{
    if not sciFlag 
    {
        sci_deploy_list(sciList).
        sci_recover_list(sciList).
        set sciFlag to true.
    }
    disp_telemetry().
    wait 0.05.
}

bays on.
wait 5.
sci_deploy_list(sciList).
sci_recover_list(sciList).