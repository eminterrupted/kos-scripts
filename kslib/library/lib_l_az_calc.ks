//This file is distributed under the terms of the MIT license, (c) the KSLib team
//=====LAUNCH AZIMUTH CALCULATOR=====
//~~LIB_LAZcalc.ks~~
//~~Version 2.2~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~
//~~Auto north/south switch by undercoveryankee~~

//To use: RUN LAZcalc.ks. SET data TO l_az_calc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).

@lazyGlobal off.

global function l_az_calc_init {
    parameter   desiredAlt,             //Altitude of desired target orbit (in *meters*)
                desiredInc,             //Inclination of desired target orbit
                autoNodeEpsilon is 10.  // How many m/s north or south
                                        // will be needed to cause a north/south switch. Pass zero to disable
                                        // the feature.

    set autoNodeEpsilon to abs(autoNodeEpsilon).
    
    //We'll pull the latitude now so we aren't sampling it multiple times
    local launchLatitude is ship:latitude.
    
    local data is list().               // A list is used to store information used by LAZcalc
    
    //Orbital altitude can't be less than sea level
    if desiredAlt <= 0 {
        print "Target altitude cannot be below sea level".
        set data to 1/0.		//Throws error
    }.
    
    //Determines whether we're trying to launch from the ascending or descending node
    local launchNode to "Ascending".
    if desiredInc < 0 {
        set launchNode to "Descending".
        
        //We'll make it positive for now and convert to southerly heading later
        set desiredInc to abs(desiredInc).
    }.
    
    //Orbital inclination can't be less than launch latitude or greater than 180 - launch latitude
    if abs(launchLatitude) > desiredInc {
        set desiredInc to abs(launchLatitude).
        hudtext("Inclination impossible from current latitude, setting for lowest possible inclination.", 10, 2, 18, red, false).
    }.
    
    if 180 - abs(launchLatitude) < desiredInc {
        set desiredInc to 180 - abs(launchLatitude).
        hudtext("Inclination impossible from current latitude, setting for highest possible inclination.", 10, 2, 18, red, false).
    }.
    
    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    local equatorialVel is (2 * constant():pi * body:radius) / body:rotationperiod.
    local targetOrbVel is sqrt(body:mu/ (body:radius + desiredAlt)).
    data:add(desiredInc).       //[0]
    data:add(launchLatitude).   //[1]
    data:add(equatorialVel).    //[2]
    data:add(targetOrbVel).     //[3]
    data:add(launchNode).       //[4]
    data:add(autoNodeEpsilon).  //[5]
    return data.
}.

function l_az_calc {
    parameter data. //pointer to the list created by l_az_calc_init

    local inertialAzimuth is arcsin(max(min(cos(data[0]) / cos(ship:latitude), 1), -1)).
    local vXRot is data[3] * sin(inertialAzimuth) - data[2] * cos(data[1]).
    local vYRot is data[3] * cos(inertialAzimuth).
    local azimuth is mod(arctan2(vXRot, vYRot) + 360, 360).     // This clamps the result to values between 0 and 360.

    if data[5] {
        local northComponent is vDot(ship:velocity:orbit, ship:north:vector).

        if northComponent > data[5] {
            set data[4] to "Ascending".
        } else if northComponent < -data[5] {
            set data[4] to "Descending".
        }.
    }.
    
    //Returns northerly azimuth if launching from the ascending node
    if data[4] = "Ascending" {
        return azimuth.
    } 
        
    //Returns southerly azimuth if launching from the descending node
    else if data[4] = "Descending" {
        
        if azimuth <= 90 {
            return 180 - azimuth.
        }
        
        else if azimuth >= 270 {
            return 540 - azimuth.
        }
    }
}.
