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
        parameter pe,
                  ecc,
                  tgtBody is ship:body.

        return (((pe + tgtBody:radius) / (1 - ecc)) * (1 + ecc)) - tgtBody:radius.
    }

    // Apoapsis and Periapsis from sma and ecc
    global function GetApPeFromSMAEcc
    {
        parameter sma,
                  ecc.

        local pe to sma * (1 - ecc).
        local ap to sma * (1 + ecc).

        return list (pe, ap).
    }

    // Eccentricity from apoapsis and periapsis
    global function GetEccFromApPe
    {
        parameter ap,
                  pe,
                  tgtBody is ship:body.

        return ((ap + tgtBody:radius) - (pe + tgtBody:radius)) / (ap + pe + (tgtBody:radius * 2)).
    }

    // Periapsis from apoapsis and eccentricity
    global function GetPeFromApEcc
    {
        parameter ap,
                  ecc,
                  tgtBody is ship:body.

        return (((ap + tgtBody:radius) / (1 + ecc)) * (1 - ecc)) - tgtBody:radius.
    }

    // Period of hohmann transfer
    global function GetPeriodFromSMA
    {
        parameter tgtSMA, 
                  tgtBody is ship:body.

        return 0.5 * sqrt((4 * constant:pi^2 * tgtSMA^3) / tgtBody:mu).
    }

    // Semimajoraxis from orbital period
    global function GetSMAFromPeriod
    {
        parameter period, 
                  tgtBody is ship:body.

        return ((tgtBody:mu * period^2) / (4 * constant:pi^2))^(1/3).
    }

    // Semimajoraxis from apoapsis, periapsis, and body
    global function GetSMAFromApPe
    {
        parameter ap,
                  pe,
                  smaBody is ship:body.

        return (pe + ap + (smaBody:radius * 2)) / 2.
    }

    // 
    global function GetTransferSma
    {
        parameter arrivalRadius,
                  parkingOrbit.

        return (arrivalRadius + parkingOrbit) / 2.
    }

    global function GetTransferPeriod
    {
        parameter xfrSMA,
                  tgtBody is ship:body.

        //return 0.5 * sqrt((4 * constant:pi^2 * xfrSMA^3) / tgtBody:mu).
        return 2 * constant:pi * sqrt(xfrSMA^3 / tgtBody:mu).
    }
    //#endregion
  // #endregion
// #endregion