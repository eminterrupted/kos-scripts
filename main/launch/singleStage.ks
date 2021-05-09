@lazyGlobal off.
clearScreen.

parameter launchPlan is lex("tgtAp", 18000).

runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_disp").

local sciFlag   to false.
local sciList   to sci_modules(). 
local tgtAp     to launchPlan["tgtAp"].

lock steering to up.

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

when ship:maxthrust <= 0.1 and stage:number > 1 then
{
    wait 0.05.
    stage.
}

lock steering to heading(90, 80, 0).

until ship:altitude >= tgtAp
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

set sciFlag to false.
lock steering to ship:prograde.

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

bays on.
wait 5.

until ship:altitude >= 250000
{
    if ship:verticalspeed <= 5 
    {
        break.
    }
    
    if not sciFlag 
    {
        sci_deploy_list(sciList).
        sci_recover_list(sciList, "ideal").
        set sciFlag to true.
    }
    disp_telemetry().
    wait 0.05.
}

sci_deploy_list(sciList).
sci_recover_list(sciList, "ideal").

local sVal to ship:prograde.
lock tsAp to time:seconds + eta:apoapsis.
lock steering to sVal.

until time:seconds >= tsAp
{
    set sVal to ship:prograde.
}

stage.

set sciList to sci_modules(). 

until false 
{
    set sVal to ship:retrograde.
}