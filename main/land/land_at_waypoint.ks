@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

local adjBurnDur    to 0.
local adjBurnDurFactor to 0.10.
local burnDur       to 0.
local tgtDescentSpd to -2.5.
local tgtHSpd       to 50.
local tgtRadarAlt   to 10.
local tti           to 0.
local wpStartDist   to 100000.

local hasDropTanks  to false.
local dropTanks     to list().

local groundAntenna to list().
local groundLights  to list().
local groundPanels  to list().
local groundRobotics to list().
local landingLights to list().

local shipBounds    to ship:bounds.

local ttiPid    to pidLoop(0.5, 0.001, 0.01, 0, 1).
local vsPid     to pidLoop(0.5, 0.001, 0.01, 0, 1).

local sVal to lookDirUp(ship:retrograde:vector, sun:position).

local tVal to 0.
local tValLim to 0.

local tgtWaypoint is nav_get_active_wp().

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

for p in ship:partsTaggedPattern("groundRobotic")
{
    local mHinge to "ModuleRoboticServoHinge".
    local mPiston to "ModuleRoboticServoPiston".
    local mRotate to "ModuleRoboticRotationServo".
    local mRotor  to "ModuleRoboticServoRotor".

    if p:hasModule(mHinge)       groundRobotics:add(p:getModule(mHinge)).
    else if p:hasModule(mPiston) groundRobotics:add(p:getModule(mPiston)).
    else if p:hasModule(mRotate) groundRobotics:add(p:getModule(mRotate)).
    else if p:hasModule(mRotor)  groundRobotics:add(p:getModule(mRotor)).
}

for p in ship:partsTaggedPattern("landingLight")
{
    landingLights:add(p:getModule("ModuleLight")).
}

lock altRadarOverride to shipBounds:bottomAltRadar.
lock throttle to tVal.
lock steering to lookDirUp(ship:retrograde:vector, sun:position).
lock tgtVector to tgtWaypoint:position.

// Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 then
{
        disp_info("Staging").
        ves_safe_stage().
        disp_info().
        if stage:number > 0 preserve.
}

disp_hud("Waiting until waypoint distance is " + wpStartDist + "m").

until tgtWaypoint:geoPosition:distance <= wpStartDist
{
    disp_orbit().
}

disp_msg("Landing sequence").

local tgtWaypointAtAlt to tgtWaypoint:geoPosition:altitudeVelocity(ship:altitude).
lock hAngleError to vAng(ship:prograde:vector, tgtWaypointAtAlt:orbit).
lock vAngleError to vAng(ship:prograde:vector, tgtWaypoint:position).

local yawPid    to pidLoop(0.01, 0.0, 0.0, -45, 45, 0.001).
local pitchPid  to pidLoop(0.1, 0.0, 0.0, -90, 90, 0.01).

disp_info("Changing inclination for intercept").
disp_info2("Current hAngleError: " + hAngleError).
if not util_check_range(hAngleError, -1, 1)
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(hAngleError, 0, 0).
    lock steering to sval.
    set tVal to 1.
    until util_check_range(hAngleError, -1, 1)
    {
        set yawPid:setpoint to 0.
        set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(hAngleError, 0, 0).
        disp_landing().
        disp_info2("Current hAngleError: " + hAngleError).
        wait 0.01.
    }
    set tVal to 0.
}









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
        disp_hud("Press 9 to discard kick stage or 0 to skip", 0, 2).
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
until altRadarOverride <= 5000 or tti < adjBurnDur
{
    vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, altRadarOverride).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    set adjBurnDur to burnDur - (burnDur * adjBurnDurFactor).
    
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

set vsPid:setpoint to -50.
disp_info("Unpowered descent to burn altitude").
until tti < adjBurnDur
{
    vsPid:update(time:seconds, ship:verticalspeed).
    set tti to land_time_to_impact(ship:verticalspeed, altRadarOverride).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    set adjBurnDur to burnDur - (burnDur * adjBurnDurFactor).
    
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

when altRadarOverride <= 250 then 
{
    disp_info("Extending landing legs").
    gear on.
    ves_activate_lights(landingLights).
}

disp_info("Powered descent").
set tVal to 1.
set ttiPid:setpoint to 1.
until altRadarOverride <= 50
{
    set tVal to max(tValLim, ttiPid:update(time:seconds, (tti - adjBurnDur))).
    
    set tti to land_time_to_impact(ship:verticalspeed, altRadarOverride).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
    set adjBurnDur to burnDur - (burnDur * adjBurnDurFactor).
        
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

set vsPid:setpoint to tgtDescentSpd.
until altRadarOverride <= tgtRadarAlt
{
    set tVal to max(tValLim, vsPid:update(time:seconds, ship:verticalspeed)).
    
    set tti to land_time_to_impact(ship:verticalspeed, altRadarOverride).
    set burnDur to mnv_active_burn_dur(ship:verticalspeed).
        
    if hasDropTanks set hasDropTanks to ves_update_droptank(dropTanks).
    disp_landing(tti, burnDur).
}

disp_info("Final descent at " + (tgtDescentSpd / 2) + "m/s").
set vsPid:setpoint to tgtDescentSpd / 2.
lock steering to lookDirUp(up:vector, sun:position).
until ship:status = "LANDED"
{
    set tVal to max(tValLim, vsPid:update(time:seconds, ship:verticalspeed)).
    
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
// Turn off the landing lights and turn on ground lights
ves_activate_lights(landingLights, false).
ves_activate_lights(groundLights).

// Activate the ground-only robotics, solar panels, comms
ves_toggle_robotics(groundRobotics).
ves_activate_solar(groundPanels).
ves_activate_antenna(groundAntenna).