// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

// *- Basic Calculations
    // #region

    // CalcDvBE :: (<scalar>, <scalar>, <scalar>, <scalar>, [<body>]) -> <list>scalar
    // Bi-elliptic transfer delta-v calc (https://en.wikipedia.org/wiki/Bi-elliptic_transfer)
    global function CalcDvBE
    {
        parameter stPe,
                  stAp,
                  tgtPe,
                  tgtAp,
                  xfrAp,
                  compMode is "pe",
                  mnvBody is ship:body.

        local dv1 to 0. // First transfer burn, boost up to xfrAp
        local dv2 to 0. // Second transfer burn at xfrAp to tgtPe
        local dv3 to 0. // Circularization to tgtAp

        local r1 to 0.
        local r2 to 0.
        local rB to 0.

        // Orbiting radii for initial, target, and transfer orbits
        if compMode = "ap" 
        {
            set r1 to stAp + mnvBody:radius.
            set r2 to tgtAp + mnvBody:radius.
        }
        else if compMode = "pe"
        {
            set r1  to stPe + mnvBody:radius.
            set r2  to tgtPe + mnvBody:radius.
        }
        else if compMode = "ap:pe" // Compare the starting apoapsis to the target periapsis
        {
            set r1 to stAp + mnvBody:radius.
            set r2 to tgtPe + mnvBody:radius.
        }
        else if compMode = "pe:ap" // Compare the starting periapsis to the target apoapsis
        {
            set r1 to stPe + mnvBody:radius.
            set r2 to tgtAp + mnvBody:radius.
        }
        set rB  to xfrAp + mnvBody:radius.

        // Semimajor-axis for transfer 1 and 2
        local a1 to (r1 + rb) / 2.
        local a2 to (r2 + rb) / 2.

        set dv1 to sqrt(((2 * mnvBody:mu) / r1) - (mnvBody:mu / a1)) - sqrt(mnvBody:mu / r1).
        set dv2 to sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a2)) - sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a1)).
        set dv3 to sqrt(((2 * mnvBody:mu) / r2) - (mnvBody:mu / a2)) - sqrt(mnvBody:mu / r2).

        return list(dv1, dv2, dv3).
    }

    // CalcDvHoh :: (<scalar>, <scalar>, <scalar>, [<body>], [<string>]) -> <list>
    // Hohmann orbital calculations
    global function CalcDvHoh
    {
        parameter stPe, 
                  stAp,
                  tgtAlt,
                  tgtBody is ship:body.

        local stSma     to GetSMAFromApPe(stAp, stPe, tgtBody).
        local tgtSma    to GetSMAFromApPe(tgtAlt, tgtAlt, tgtBody).
        local xfrSma    to (stSma + tgtSma) / 2.
        
        // print "stSma     : " + round(stSma) at (2, 20).
        // print "tgtSma    : " + round(tgtSma) at (2, 21).
        // print "xfrSma    : " + round(xfrSma) at (2, 22).

        local vPark to sqrt(tgtBody:mu * ((2 / stSma) - (1 / stSma))).
        local vTgt to sqrt(tgtBody:mu * ((2 / tgtSma) - (1 / tgtSma))).
        local vTransferPe to sqrt(tgtBody:mu * ((2 / stSma) - (1 / xfrSma))).
        local vTransferAp to sqrt(tgtBody:mu * ((2 / tgtSma) - (1 / xfrSma))).
        //local vTransfer to sqrt(tgtBody:mu * ((2 / stSma) - (1 / xfrSma))).

        // print "vPark     : " + round(vPark, 2) at (2, 25).
        // print "vTransfer : " + round(vTransfer, 2) at (2, 26).
        // print "vTransferPe: " + round(vTransferPe, 2) at (2, 27).
        // print "vTransferAp: " + round(vTransferAp, 2) at (2, 28).
        // print "vTgt      : " + round(vTgt, 2) at (2, 29).

        // print "xfr dV    : " + round(vTransferPe - vPark, 2) at (2, 31).
        // print "arr dV    : " + round(vTgt - vTransferAp, 2) at (2, 32).
        // Breakpoint().

        return list(vTransferPe - vPark, vTgt - vTransferAp).
    }

    // CalcDvHoh :: (<scalar>, <scalar>, <scalar>, <scalar>, [<body>], [<string>]) -> <list>
    // Hohmann orbital calculations
    global function CalcDvHoh2
    {
        parameter stPe, 
                  stAp,
                  tgtPe,
                  tgtAp,
                  mnvBody.
                  
        local stSma  to GetSMAFromApPe(stAp, stPe, mnvBody).
        local tgtSma to GetSMAFromApPe(tgtAp, tgtPe, mnvBody).
        local xfrSma to (stSma + tgtSma) / 2.

        local vPark to sqrt(mnvBody:mu * ((2 / stSma) - (1 / stSma))).
        local vTgt to sqrt(mnvBody:mu * ((2 / tgtSma) - (1 / tgtSma))).
        local vTransferPe to sqrt(mnvBody:mu * ((2 / stSma) - (1 / xfrSma))).
        local vTransferAp to sqrt(mnvBody:mu * ((2 / tgtSma) - (1 / xfrSma))).

        return list(vTransferPe - vPark, vTransferAp - vTgt).
    }

    // CalcDvHyperCapture :: <scalar>, <scalar>, <ship>, <body> -> <scalar>
    // Returns the dV needed to capture given the current hyperbolic orbit
    global function CalcDvHyperCapture
    {
        parameter ves is ship,
                  stPe is ves:periapsis,
                  tgtAp is ves:periapsis,
                  tgtBody is ship:body.

        local aCur to ves:orbit:semimajoraxis.
        local aTgt to GetSMAFromApPe(tgtAp, stPe, tgtBody).
        local rPe to stPe + tgtBody:radius.

        local vPeCur     to sqrt(tgtBody:mu * ((2 / rPe) - (1 / aCur))).
        local vPeTgt     to sqrt(tgtBody:mu * ((2 / rPe) - (1 / aTgt))).

        return vPeTgt - vPeCur.
    }
//#endregion
// #endregion