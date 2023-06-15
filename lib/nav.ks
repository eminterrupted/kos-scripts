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
  
    // *- Orbital calcuations
    // #region

    //#region -- Orbit Calculations
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

    // 
    global function GetTransferSma
    {
        parameter _arrivalRadius,
                  _parkingOrbit.

        return (_arrivalRadius + _parkingOrbit) / 2.
    }

    global function GetTransferPeriod
    {
        parameter _xfrSMA,
                  _tgtBody is ship:body.

        //return 0.5 * sqrt((4 * constant:pi^2 * xfrSMA^3) / tgtBody:mu).
        return 2 * constant:pi * sqrt(_xfrSMA^3 / _tgtBody:mu).
    }
    //#endregion
  // #endregion
// #endregion