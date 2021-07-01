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

local hasDropTanks  to false.
local dropTanks     to list().

local groundAntenna to list().
local groundLights  to list().
local groundPanels  to list().
local landingLights to list().

if ship:partsTaggedPattern("dropTank"):length > 0
{
    set hasDropTanks    to true.
    set dropTanks       to ves_get_drop_tanks().
}

for p in ship:partsTaggedPattern("groundAntenna")
{
    groundAntenna:add(p:getModule("ModuleRTAntenna")).
}

for p in ship:partsTaggedPattern("groundLight")
{
    groundLights:add(p:getModule("ModuleLight")).
}

for p in ship:partsTaggedPattern("groundPanel")
{
    groundPanels:add(p:getModule("ModuleDeployableSolarPanel")).
}

for p in ship:partsTaggedPattern("landingLight")
{
    landingLights:add(p:getModule("ModuleLight")).
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
ag10 off.
until ship:groundspeed <= tgtHSpd or ag10
{
    disp_orbit().
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    if ag10 break.
}
ag10 off.

set tVal to 0.
wait 1.

ag9 off.
ag10 off.
if stage:number > 0 
{
    local ts to time:seconds.
    lock timer to time:seconds - ts.
    until false
    {
        disp_hud("Press 9 for non-return landings to stage, or 0 to skip staging", 0, 2).
        disp_hud("Skipping in " + round(10 - timer), 0, 2).
        if ag9 {
            disp_hud("Staging", 0, 2).
            stage.
            wait 1.
            stage.
            break.
        }
        if timer > 10 or ag10 {
            disp_hud("Skipping staging", 0, 2).
            break.
        }
        wait 1.
    }
}

lock steering to lookDirUp(land_srfretro_or_up():vector, sun:position). 
disp_info("Unpowered descent to 5000m altitude").
until alt:radar <= 5000 or tti < burnDur
{
    vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
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
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

when alt:radar <= 250 then 
{
    disp_info("Extending landing legs").
    gear on.
    ves_activate_lights(landingLights).
}

disp_info("Powered descent, slowing to -10m/s Vertical Speed").
set tVal to 1.
set ttiPid:setpoint to 1.
until alt:radar <= 50
{
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    set tVal to ttiPid:update(time:seconds, (tti - burnDur)).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

set vsPid:setpoint to tgtDescentSpd.
until alt:radar <= tgtRadarAlt
{
    set tVal to vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, alt:radar).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
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
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}
disp_msg("Touchdown").
disp_info().
set tVal to 0.

for e in ves_active_engines() {
    e:shutdown.
}

wait 1.
// Turn off the landing lights
ves_activate_lights(landingLights, false).

// Activate the ground-only solar panels, comms, and lights
ves_activate_solar(groundPanels).
ves_activate_antenna(groundAntenna).
ves_activate_lights(groundLights).