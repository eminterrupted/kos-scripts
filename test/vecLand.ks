@lazyGlobal off.
clearScreen.

parameter wp.

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

local hasDropTanks  to false.
local dropTanks     to list().

local groundAntenna to list().
local groundLights  to list().
local groundPanels  to list().
local landingLights to list().

local shipBounds    to ship:bounds.

local ttiPid    to pidLoop(0.5, 0.001, 0.01, 0, 1).
local vsPid     to pidLoop(0.5, 0.001, 0.01, 0, 1).

local tVal to 0.
local tValLim to 0.

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

lock altRadarOverride to shipBounds:bottomAltRadar.
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











// LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2.  //surface gravity for current body
// local throt to 0.
// lock steering to throt.
// LOCAL vecTar IS SHIP:FACING:VECTOR.  //initializing the target vector with the current facing vector of the ship
// LOCK STEERING TO vecTar.
// UNTIL FALSE {
//     LOCAL faceVec IS SHIP:FACING:VECTOR.    // the direction the ship is facing

//     LOCAL velVec IS SHIP:VELOCITY:SURFACE.  // velocity vector
//     SET vdVelVec TO VECDRAW(v(0,0,0),velVec,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).

//     LOCAL tarVec IS wp:POSITION.        // vector to target
//     SET vdTarVec TO VECDRAW(v(0,0,0),tarVec,RGB(1,0,0),"Target Vector",1,TRUE,0.1,TRUE).

//     LOCAL accel IS (SHIP:AVAILABLETHRUST / SHIP:MASS - surfGrav) * 0.5 .// 1/2 ship's available acceleration minus gravity.
//     LOCAL wantVelVec IS tarVec:NORMALIZED * SQRT(2 * tarVec:MAG * accel). // converting the distance to desired velocity using kinematic equation
//       // normalizing a vector keeps it's direction but sets the length (magnitude) to 1
//       // multiplying a vector by a number multiples it's magnitude by that number
//     SET vdWantVelVec TO VECDRAW(v(0,0,0),wantVelVec,RGB(0,1,0),"Wanted Velocity Vector",1,TRUE,0.2,TRUE).

//     LOCAL errorVec IS wantVelVec - velVec. // the difference between the wanted velocity and the current velocity
//     SET vdErrorVec TO VECDRAW(velVec,errorVec,RGB(0,0,1),"Error Vector",1,TRUE,0.1,TRUE).

//     IF VDOT(errorVec,velVec) < 0 { // a vector dot product (VDOT) is some what complicated
//         SET vecTar TO errorVec.    // but in this if the result is negative then the 2 vectors are more than 90 degrees away from each other
//     } ELSE {                       // which means that the desired velocity is less than the current velocity and as such can be used for steering input
//         SET vecTar TO -errorVec.   // if the result is still positive then the desired velocity is larger than the current velocity so we will use the inverse for steering
//     }
//     SET throt TO VDOT(faceVec,errorVec) / accel.
//                                         // in this case because the results of SHIP:FACING:VECTOR will always be have a magnitude of 1
//                                         // the result of the VDOT will be how long the errorVec is along the faceVec axis
//                                         // think of it as like measuring the vertical height of a tilted thing
//                                         // but where the vector with a magnitude of 1 defines the "up" direction
//                                         // The division by accel is because that represents what the throttle can do given an error
//     WAIT 0.
// }