@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

local burnDur       to 0.
local tgtDescentSpd to -2.5.
local tgtHSpd       to 50.
local tgtRadarAlt   to 25.
local tti           to 0.

local lightList     to list().
local panelList     to list().


for p in ship:partsTaggedPattern("landingLight")
{
    lightList:add(p:getModule("ModuleLight")).
}

for p in ship:partsTaggedPattern("groundPanel")
{
    panelList:add(p:getModule("ModuleDeployableSolarPanel")).
}

local ttiPid    to pidLoop(0.5, 0.001, 0.01, 0, 1).
local vsPid     to pidLoop(0.5, 0.001, 0.01, 0, 1).

local tVal to 0.
lock throttle to tVal.
lock steering to lookDirUp(ship:retrograde:vector, sun:position).

// Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 then
{
        disp_info("Staging").
        ves_safe_stage().
        disp_info().
        if stage:number > 0 preserve.
}

disp_hud("Press 0 to initiate landing sequence").
ag10 off.
until ag10
{
    disp_orbit().
}

disp_msg("Landing sequence").
disp_info("Cancelling horizontal velocity to " + tgtHSpd + "m/s").
set tVal to 1.
until ship:groundspeed <= tgtHSpd
{
    disp_orbit().
}

set tVal to 0.
wait 1.

ag9 off.
ag10 off.
if stage:number > 0 
{
    disp_hud("Press 9 for non-return landings to stage, or 0 for return landings").
    wait until ag9 or ag10.
    if ag9
    {
        until stage:number = 0
        {
            stage.
            wait 0.1.
        }
    }
}

lock steering to lookDirUp(land_srfretro_or_up():vector, sun:position). 
disp_info("Unpowered descent to 5000m altitude").
until alt:radar <= 5000 or tti < burnDur
{
    vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    disp_landing(tti, burnDur).
}

set vsPid:setpoint to -25.
disp_info("Unpowered descent to burn altitude").
until tti < burnDur 
{
    //set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    disp_landing(tti, burnDur).
}

when alt:radar <= 150 then 
{
    disp_info("Extending landing legs").
    gear on.
    ves_activate_lights(lightList).
}

disp_info("Powered descent, slowing to -10m/s Vertical Speed").
set tVal to 1.
set ttiPid:setpoint to 1.
until alt:radar <= 100 
{
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    set tVal to ttiPid:update(time:seconds, (tti - burnDur)).
    disp_landing(tti, burnDur).
}

set vsPid:setpoint to tgtDescentSpd.
until alt:radar <= tgtRadarAlt
{
    set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    disp_landing(tti, burnDur).
}

disp_info("Final descent at " + (tgtDescentSpd / 2) + "m/s").
set vsPid:setpoint to tgtDescentSpd / 2.
lock steering to lookDirUp(up:vector, sun:position).
until ship:status = "LANDED"
{
    set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(time:seconds, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    disp_landing(tti, burnDur).
}
disp_msg("Touchdown").
disp_info().
set tVal to 0.

for e in ves_active_engines() {
    e:shutdown.
}

ves_activate_solar(panelList).