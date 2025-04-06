// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    // #endregion
    
    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
    
    // *- True Anomaly
    //#region

    // UTimeAtTA :: _obtIn<Orbit>, _taDeg<Scalar> -> UTimeAtTA<Scalar>
    // From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
    // Returns the UTime of a future true anomaly point in a given orbit
    global function GetUTimeAtTA
    {
        parameter _obtIn,  // Orbit to predict for
                  _taDeg.  // true anomaly we need in degrees

        local targetTime is GetTimePEtoTA(_obtIn, _taDeg).
        local curTime is GetTimePEtoTA(_obtIn, _obtIn:TrueAnomaly).

        local utimeAtTA is time:seconds + targetTime - curTime.
        
        // If negative, we've passed it so return the next orbit
        if utimeAtTA < time:seconds
        { 
            set utimeAtTA to utimeAtTA + _obtIn:period. 
        }

        return utimeAtTA.
    }

    // GetTimePEtoTA :: 
    // The time it takes to get from Pe to a given true anomaly
    global function GetTimePEtoTA
    {
        parameter _obtIn,  // Orbit to predict for
                  _taDeg.  // true anomaly in degrees

        local ecc is _obtIn:eccentricity. 
        local sma is _obtIn:semimajoraxis.
        local eAnomDeg is ArcTan2( Sqrt(1 - ecc^2) * Sin(_taDeg), ecc + Cos(_taDeg)).
        local eAnomRad is eAnomDeg * constant:degtorad.
        local mAnomRad is eAnomRad - ecc * Sin(eAnomDeg).

        return mAnomRad / Sqrt( _obtIn:body:mu / sma^3 ).
    }

    // UTimeAtLAN :: _obtIn<Orbit>, _taDeg<Scalar> -> UTimeAtTA<Scalar>
    // From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
    // Returns the UTime of a future true anomaly point in a given orbit
    global function GetUTimeAtLAN
    {
        parameter _ves,  // Vessel 
                  _anType is 0.  // 0: AN, 1: DN

        local vesObt is _ves:Orbit.
        local TAofAN to choose GetANTrueAnomaly(_ves) if _anType = 0 else GetDNTrueAnomaly(_ves).

        return GetUTimeAtTA(_ves:Orbit, TAofAN).
        
        // local targetTime is GetTimePEtoTA(vesObt, TAofAN).
        // local curTime is GetTimePEtoTA(vesObt, vesObt:TrueAnomaly).

        // local utimeAtTA is time:seconds + targetTime - curTime.
        
        // // If negative, we've passed it so return the next orbit
        // if utimeAtTA < time:seconds
        // { 
        //     set utimeAtTA to utimeAtTA + vesObt:period. 
        // }

        // return utimeAtTA.
    }

    // GetANTrueAnomaly
    global function GetANTrueAnomaly
    {
        parameter _ves.

        local vesselTA to _ves:Orbit:TrueAnomaly.
        local angToAN to kslib_nav_ang_to_body_asc_node(_ves).
        if angToAN < 0
        {
            set angToAN to angToAN + 360.
        }
        return Mod(vesselTA + angToAN, 360).
    }

    // GetDNTrueAnomaly
    global function GetDNTrueAnomaly
    {
        parameter _ves.

        local vesselTA to _ves:Orbit:TrueAnomaly.
        local angToDN to kslib_nav_ang_to_body_desc_node(_ves).
        if angToDN < 0
        {
            set angToDn to angToDN + 360.
        }
        return Mod(vesselTA + angToDN, 360).
    }


    // Find the ascending node where orbit 0 crosses the plane of orbit 1
    // Answer is returned in the form of true anomaly of orbit 0 (angle from
    // orbit 0's Pe). Descending node inverse (+180)
    global function GetAscNodeTA
    {
        parameter _vesObt, // This should be the ship orbit
                  _tgtObt. // This should be the target orbit

        // Normals of the orbits
        local vesNrm to kslib_nav_obt_normal(_vesObt).
        local tgtNrm to kslib_nav_obt_normal(_tgtObt).

        // Unit vector pointing from body's center towards the target normal
        local vVesToTgt is VCrs(vesNrm, tgtNrm).

        // Vector pointing from body center to obt_0 current position
        local vBodyToVes is _vesObt:position - _vesObt:body:position.

        // How many true anomaly degrees ahead of my current true anomaly
        local diffNodeTA is VAng(vVesToTgt, vBodyToVes).

        // I think this will give us pos / neg depending on how 
        // far ahead it is
        local signVec is VCrs(vVesToTgt, vBodyToVes).
        
        // If the sign_check_vec is negative (meaning more than 180 degrees 
        // in front of us), it will result in the normal being negative. In
        // this case, we subtract ta_ahead from 360 to get degrees from 
        // current position. 
        if VDot(vesNrm, signVec) < 0
        {
            set diffNodeTA to 360 - diffNodeTA.
        }

        // Add current true anomaly to our calculated ta_ahead to get the 
        // absolute true anomaly
        return Mod( _vesObt:trueanomaly + diffNodeTA, 360).
    }

    // GetAltitudeAtTrueAnomaly :: _obtIn<Orbit>, _ta<Scalar> -> Altitude(ASL)<Scalar>
    // Get an orbit's altitude at a given true anomaly angle of it
    global function GetAltitudeAtTrueAnomaly
    {
        parameter _obtIn, // Orbit to check
                  _ta.    // TA in degrees

        local ecc is _obtIn:eccentricity.
        return _obtIn:SemimajorAxis * (1 - ecc ^ 2) / (1 + ecc * Cos(_ta)) - _obtIn:Body:Radius.
    }
    //#endregion

    // *- Velocity
    // #region

    // GetTransferVelocityFromSMA :: _startSMA<Scalar>, _endSMA<Scalar>, _body<Body> -> (transferVelocity)<Scalar>
    // Transfer velocity from start and end semimajoraxis
    global function GetTransferVelocityFromSMA
    {
        parameter _startSMA,
                  _endSMA,
                  _body is ship:body.

        return sqrt(_body:mu * ((2 / _startSMA) - (1 / _endSMA))).
    }

    // GetVelocityAtTrueAnomaly :: _ves<Vessel>, _obt<Orbit>, _anomaly<?> -> Velocity<VelocityItem>
    // Velocity given a true anomaly
    global function GetVelocityAtTrueAnomaly
    {
        parameter ves,
                orbitIn,
                anomaly.

        local etaToAnomaly to GetUTimeAtTA(orbitIn, anomaly).
        return velocityAt(ves, etaToAnomaly):orbit:mag.
    }
    
    // #endregion

// #endregion