// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Anomaly Calculation
    // #region

    // https://en.wikipedia.org/wiki/Eccentric_anomaly
    global function GetEccAnomaly
    {
        parameter _obj,
                  _timeFromNow is 0.

        local objEcc to objObt:Eccentricity.
        local ta to GetTrueAnomaly(_obj, _timeFromNow).
        local cosEccAnomaly to (objEcc + Cos(ta)) / ( 1 + (objEcc * Cos(ta))).
        local eccAnomaly to ArcCos(cosEccAnomaly).
        // local sinEccAnomaly to (Sqrt(1 - objEcc^2) * Sin(ta)) / (1 + (objEcc * Cos(ta))).
        // local eccAnomaly to ArcSin(sinEccAnomaly).

        return eccAnomaly.
    }

    // https://en.wikipedia.org/wiki/True_anomaly
    global function GetTrueAnomaly
    {
        parameter _obj,
                  _timeFromNow is 0.

        local tsTA      to Time:Seconds + _timeFromNow.
        local veloVecTA to VelocityAt(_obj, tsTA):Orbit.
        local posVecTA  to PositionAt(_obj, tsTA). 
        local eccVecTA  to (veloVecTA * (posVecTA * veloVecTA)) / _obj:Body:Mu.
        local ta        to ArcCos((eccVecTA * posVecTA) / (Abs(eccVecTA) * Abs(posVecTA))).
        if (posVecTA * veloVecTA) < 0 
        {
            set ta to (2 * constant:pi) - ta.
        }
        return ta.
    }

    // Returns the mean anomaly of the provided object, with optional projection into the future
    // https://en.wikipedia.org/wiki/Mean_anomaly
    global function GetMeanAnomaly
    {
        parameter _obj,
                  _timeFromNow is 0.

        local tsMA to Time:Seconds + _timeFromNow.
        local objObt to choose _obj:Orbit if _timeFromNow = 0 else OrbitAt(_obj, tsMA).

        local timeAdded to 0.
        if _timeFromNow > objObt:ETA:Periapsis
        {
            until timeAdded > _timeFromNow 
            {
                set timeAdded to timeAdded + objObt:Period.
            }
        }

        local meanAngMotion to (2 * Constant:Pi) / objObt:Period.
        local tsPe to (Time:Seconds - (objObt:Period - objObt:ETA:Periapsis)) + timeAdded.
        return meanAngMotion * (tsMA - tsPe). // Mean Anomaly
    }
    // #endregion

    // *- Orbital Ap / Pe / SMA / ECC calcuations
    // #region

    // Apoapsis from periapsis and eccentricity
    global function GetApFromPeEcc
    {
        parameter _pe,
                  _ecc,
                  _tgtBody is ship:body.

        return (((_pe + _tgtBody:radius) / (1 - _ecc)) * (1 + _ecc)) - _tgtBody:radius.
    }

    // Apoapsis and Periapsis from sma and ecc
    global function GetApPeFromSMAEcc
    {
        parameter _sma,
                  _ecc.

        local pe to _sma * (1 - _ecc).
        local ap to _sma * (1 + _ecc).

        return list (pe, ap).
    }

    // Eccentricity from apoapsis and periapsis
    global function GetEccFromApPe
    {
        parameter _ap,
                  _pe,
                  _tgtBody is ship:body.

        return ((_ap + _tgtBody:radius) - (_pe + _tgtBody:radius)) / (_ap + _pe + (_tgtBody:radius * 2)).
    }

    // Periapsis from apoapsis and eccentricity
    global function GetPeFromApEcc
    {
        parameter _ap,
                  _ecc,
                  _tgtBody is ship:body.

        return (((_ap + _tgtBody:radius) / (1 + _ecc)) * (1 - _ecc)) - _tgtBody:radius.
    }

    // Period of hohmann transfer
    global function GetPeriodFromSMA
    {
        parameter _tgtSMA, 
                  _tgtBody is ship:body.

        return 0.5 * sqrt((4 * constant:pi^2 * _tgtSMA^3) / _tgtBody:mu).
    }

    // Semimajoraxis from orbital period
    global function GetSMAFromPeriod
    {
        parameter _period, 
                  _tgtBody is ship:body.

        return ((_tgtBody:mu * _period^2) / (4 * constant:pi^2))^(1/3).
    }

    // Semimajoraxis from apoapsis, periapsis, and body
    global function GetSMAFromApPe
    {
        parameter _ap,
                  _pe,
                  _smaBody is ship:body.

        return (_pe + _ap + (_smaBody:radius * 2)) / 2.
    }

    // Semimajoraxis of transfer orbit
    global function GetTransferSMA
    {
        parameter _arrivalSMA,
                  _parkingSMA.

        return (_arrivalSMA + _parkingSMA) / 2.
    }
    // #endregion

    // Orbital Time Calculations
    // #region
    // Returns the period of a transfer SMA
    global function GetTransferPeriod
    {
        parameter _xfrSMA,
                  _stBody is ship:body.

        //return 0.5 * sqrt((4 * constant:pi^2 * xfrSMA^3) / tgtBody:mu).
        return 2 * constant:pi * sqrt(_xfrSMA^3 / _stBody:mu).
    }
    //#endregion

    // Orbital Position Projections
    // #region

    // GetPhaseAngleAtTime :: _tgtObj<Orbitable>, [_ogObj<Orbitable>], [_timeFromNow<Scalar>] -> phase<Scalar>
    // Heavily based on kslib_nav_phase_angle, modified for future phase prediction
    global function GetPhaseAngleAtTime
    {
        parameter _tgtObj,
                  _ogObj is Ship,
                  _ts is Time:Seconds.

        local common_ancestor is 0.
        local my_ancestors is list().
        local your_ancestors is list().

        my_ancestors:Add(OrbitAt(_ogObj, _ts):Body).
        until not(my_ancestors[my_ancestors:Length-1]:hasBody) 
        {
            my_ancestors:Add(my_ancestors[my_ancestors:Length-1]:Body).
        }
        your_ancestors:Add(OrbitAt(_tgtObj, _ts):Body).
        until not(your_ancestors[your_ancestors:Length-1]:hasBody) 
        {
            your_ancestors:Add(your_ancestors[your_ancestors:Length-1]:Body).
        }

        for my_ancestor in my_ancestors 
        {
            local found is false.
            for your_ancestor in your_ancestors 
            {
                if my_ancestor = your_ancestor 
                {
                    set common_ancestor to my_ancestor.
                    set found to true.
                    break.
                }
            }
            if found {
                break.
            }
        }

        local vel is VelocityAt(_ogObj, _ts):orbit.
        local common_ancestor_pos to PositionAt(common_ancestor, _ts).
        local my_ancestor is my_ancestors[0].
        until my_ancestor = common_ancestor 
        {
            set vel to vel + VelocityAt(my_ancestor, _ts):orbit.
            set my_ancestor to my_ancestor:Body.
        }
        local tgt_pos to PositionAt(_tgtObj, _ts).
        local binormal is vcrs(-common_ancestor_pos:normalized, vel:normalized):normalized.

        local phase is vang(
            -common_ancestor_pos:normalized,
            vxcl(binormal, tgt_pos - common_ancestor_pos):normalized
        ).
        local signVector is vcrs(
            -common_ancestor_pos:normalized,
            (tgt_pos - common_ancestor_pos):normalized
        ).
        local sign is vdot(binormal, signVector).
        if sign < 0 {
            return 360 - phase.
        }
        else {
            return phase.
        }
    }
    // #endregion

    // Situational Parameter Calculations
    // #region

    // GetLocalGrav :: [_body<Orbitable>], [_alt<Scalar>] -> <scalar>
    // Returns the local gravity given an orbitable and an altitude above it. Defaults to current vessel position.
    global function GetLocalGravity
    {
        parameter _body is Ship:Body,
                  _alt is Ship:Altitude.

        return (Constant:g * _body:Mass) / (_body:radius + _alt)^2.
    }
    // #endregion
// #endregion