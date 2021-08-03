@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/lib_mnv").

disp_main(scriptPath(), false).

local hoverAlt to 1000.
local slowAscent to 2.5.
local slowDescent to -5.
local finalDescent to -2.5.

local altPid to pidLoop(0.05, 0.01, 0.1, 0, 1).
set altPid:setpoint to hoverAlt.

local vsPid to pidLoop(0.5, 0.001, 0.01, 0, 1).
set vsPid:setpoint to slowAscent.


local tVal to 0.
lock throttle to tVal.

sas off.
lock steering to up.

ag10 off.
wait until ag10.
stage.

set tVal to 1.
until ship:altitude >= hoverAlt * 0.8
{
    vsPid:update(time:seconds, ship:verticalspeed).
    altPid:update(time:seconds, ship:altitude).
    telemetry().
    wait 0.
}
clearScreen.

until ship:altitude >= hoverAlt * 0.95
{
    set tVal to vsPid:update(time:seconds, ship:verticalSpeed).
    telemetry().
    pid_values(vsPid).
}
clearScreen.

ag9 off.
until ship:liquidFuel <= 7.5 or ag9
{
    set tVal to altPid:update(time:seconds, ship:altitude).
    telemetry().
    pid_values(altPid).
    wait 0.
}
clearScreen.
set tVal to 0.

until false
{
    local tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    local burnDur to mnv_active_burn_dur(ship:verticalspeed).
    if tti < burnDur break.
    
    tti_telem(tti, burnDur).
    telemetry().
    wait 0.
}
clearScreen.
lock steering to choose srfRetrograde if ship:verticalSpeed < 0 else up.
set tVal to 1.

altPid:reset.
set altPid:setpoint to 10.

vsPid:reset.
set vsPid:setpoint to slowDescent.

until ship:verticalspeed >= -5
{
    altPid:update(time:seconds, alt:radar).
    vsPid:update(time:seconds, ship:verticalspeed).
    telemetry().
    wait 0.
}
clearScreen.
lock steering to up.

until alt:radar <= 10
{
    set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    telemetry().
    pid_values(vsPid).
    wait 0.
}

set vsPid:setpoint to finalDescent.
until alt:radar <= 2
{
    set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    telemetry().
    pid_values(vsPid).
}

set tVal to 0.

until false
{
    wait 0.
}

local function pid_values
{
    parameter pid.

    print "setpoint: " + pid:setpoint at (0, 10).
    print "output  : " + round(pid:output, 5) at (0, 11).
    print "pterm   : " + round(pid:pterm, 5) at (0, 12).
    print "iterm   : " + round(pid:iterm, 5) at (0, 13).
    print "dterm   : " + round(pid:dterm, 5) at (0, 14).
}

local function telemetry
{
    print "ALT:RADAR: " + alt:radar at (0, 5).
    print "VERTSPEED: " + ship:verticalspeed at (0, 6).
}

local function tti_telem
{
    parameter tti, burnDur.

    print "TTI     : " + tti at (0, 17).
    print "BURN DUR: " + burnDur at (0, 18).
}