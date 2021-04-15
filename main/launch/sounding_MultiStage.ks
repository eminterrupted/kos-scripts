@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").

local sciFlag   to false.
local sciList   to sci_modules(). 
local sVal      to up.

lock steering to sVal.

// Main
sci_deploy_list(sciList).
wait 1.
sci_recover_list(sciList, "ideal").

local ts to time:seconds + 10.
until time:seconds >= ts
{
    print "Countdown: " + round(time:seconds - ts) + " " at (2, 2).
}
stage.

when ship:maxthrust <= 0.1 then
{
    wait 0.05.
    stage.
    if stage:number > 2 preserve.
}

until ship:altitude >= 250 
{
    set sVal to up.
}

set sVal to heading(90, 85, -90).

until ship:altitude >= 18000
{
    if not sciFlag
    {
        sci_deploy_list(sciList).
        sci_recover_list(sciList, "ideal").
        set sciFlag to true.
    }
    disp_telemetry().
    wait 0.05.
}

set sVal to ship:prograde.
set sciFlag to false.

until ship:altitude >= body:atm:height
{
    if not sciFlag 
    {
        sci_deploy_list(sciList).
        sci_recover_list(sciList, "ideal").
        set sciFlag to true.
    }
    disp_telemetry().
    wait 0.05.
}

stage.

bays on.
wait 5.
sci_deploy_list(sciList).
sci_recover_list(sciList, "ideal").

for m in ship:modulesNamed("RealChuteModule")
{
    util_do_event(m, "arm parachute").
}

bays off.

until ship:altitude <= body:atm:height 
{
    set sVal to ship:retrograde.
}

unlock steering.