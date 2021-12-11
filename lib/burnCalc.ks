// -- dv Calculations

//#include "0:/lib/vessel.ks"

// Burn DV Calculations
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
                  mnvBody is ship:body,
                  compMode is "pe".

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
        else
        {
            set r1  to stPe + mnvBody:radius.
            set r2  to tgtPe + mnvBody:radius.
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
                  tgtBody is ship:body,
                  mode is "ap".

        local stSma to GetSMA(stPe, stAp, tgtBody).
        local tgtSma to GetSMA(tgtAlt, tgtAlt, tgtBody).
        local xfrSma to (stSma + tgtSma) / 2.
        
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

        return list(vTransferPe - vPark, vTransferAp - vTgt).
    }

    // CalcDvHoh :: (<scalar>, <scalar>, <scalar>, <scalar>, [<body>], [<string>]) -> <list>
    // Hohmann orbital calculations
    global function CalcDvHoh2
    {
        parameter stPe, 
                  stAp,
                  tgtPe,
                  tgtAp,
                  mnvBody,
                  burnTA.
                  
        //local stRad  to AltAtTA(ship:orbit, burnTA) + mnvBody:radius.
        local stSma  to GetSMA(stPe, stAp, mnvBody).
        local tgtSma to GetSMA(tgtPe, tgtAp, mnvBody).
        local xfrSma to (stSma + tgtSma) / 2.
        
        // print "stSma     : " + round(stSma) at (2, 20).
        // print "tgtSma    : " + round(tgtSma) at (2, 21).
        // print "xfrSma    : " + round(xfrSma) at (2, 22).

        local vPark to sqrt(mnvBody:mu * ((2 / stSma) - (1 / stSma))).
        local vTgt to sqrt(mnvBody:mu * ((2 / tgtSma) - (1 / tgtSma))).
        local vTransferPe to sqrt(mnvBody:mu * ((2 / stSma) - (1 / xfrSma))).
        local vTransferAp to sqrt(mnvBody:mu * ((2 / tgtSma) - (1 / xfrSma))).
        //local vTransfer to sqrt(tgtBody:mu * ((2 / stSma) - (1 / xfrSma))).

        // print "vPark     : " + round(vPark, 2) at (2, 25).
        // print "vTransfer : " + round(vTransfer, 2) at (2, 26).
        // print "vTransferPe: " + round(vTransferPe, 2) at (2, 27).
        // print "vTransferAp: " + round(vTransferAp, 2) at (2, 28).
        // print "vTgt      : " + round(vTgt, 2) at (2, 29).

        // print "xfr dV    : " + round(vTransferPe - vPark, 2) at (2, 31).
        // print "arr dV    : " + round(vTgt - vTransferAp, 2) at (2, 32).
        // Breakpoint().

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
        local aTgt to GetSMA(stPe, tgtAp, tgtBody).
        local rPe to stPe + tgtBody:radius.

        local vPeCur     to sqrt(tgtBody:mu * ((2 / rPe) - (1 / aCur))).
        local vPeTgt     to sqrt(tgtBody:mu * ((2 / rPe) - (1 / aTgt))).

        return vPeTgt - vPeCur.
    }
//#endregion


// Burn Duration / Stages
// #region

    // BurnDur :: (<scalar>) -> <list>scalar [Full, Half]
    // Returns the time to burn a given dV, including the halfway burn dur for burn start timing
    // Also returns values with staging time included
    global function CalcBurnDur
    {
        parameter dv.

        local stgObj to BurnStagesUsed(dv).
        local durObj to BurnDurStage(stgObj).
        
        local fullDurWithStaging to durObj["Full"].
        local halfDurWithStaging to durObj["Half"].

        if stgObj["Full"]:keys:length > 1 
        {
            local stageWaitTime to 1.
            from { local stg to stage:number - 1.} until stg = 0 step { set stg to stg - 1.} do
            {
                if stgObj["Full"]:hasKey(stg) set fullDurWithStaging to fullDurWithStaging + stageWaitTime.
                if stgObj["Half"]:hasKey(stg) set halfDurWithStaging to halfDurWithStaging + stageWaitTime.
            }
        }
        set durObj["FullStaged"] to fullDurWithStaging.
        set durObj["HalfStaged"] to halfDurWithStaging.
        
        return list(durObj["Full"], durObj["FullStaged"], durObj["Half"], durObj["HalfStaged"]).
    }

    // BurnDurStage :: (<lexicon>) -> <lexicon>
    // Returns the time in secs to burn the dv defined by the result of BurnStagesUsed
    global function BurnDurStage
    {
        parameter dvStgObj.

        local burnDurObj to lex(
            "Full", 0,
            "Half", 0
        ).

        for key in dvStgObj["Full"]:keys
        {
            local exhVel to GetExhVel(GetEnginesByStage(key)).
            local stgThr to GetStageThrust(key, "poss").
            local vesMass to StageMass(key)["ship"].
            // print "exhVel: " + exhVel.
            // print "stgThr: " + stgThr.
            // print "vesMass: " + vesMass.

            local fullDur to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj["Full"][key] / exhVel)))).
            set burnDurObj["Full"] to burnDurObj["Full"] + fullDur.
            
            if dvStgObj["Half"]:hasKey(key)
            {
                local halfDur to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj["Half"][key] / exhVel)))).
                set burnDurObj["Half"] to burnDurObj["Half"] + halfDur.
            }
        }

        return burnDurObj.
    }


    // BurnStagesUsed :: (<scalar>) -> <lexicon>
    // Given a target burn dV, returns a nested lex of stages->dV to be used for full and half-duration burn calcs
    global function BurnStagesUsed
    {
        parameter dv.

        set dv to abs(dv).
        local dvHalf to dv / 2.
        local dvFullObj to lex().
        local dvHalfObj to lex().

        from { local stg to stage:number.} until dv <= 0 or stg < -1 step { set stg to stg - 1.} do {
            local breakFlag to false.
            local dvStg to AvailStageDV(stg).
            if dvStg > 0 
            {
                // Full
                if dv <= dvStg
                {
                    set dvFullObj[stg] to dv.
                    set breakFlag to true.
                }
                else
                {
                    set dvFullObj[stg] to dvStg.
                    set dv to dv - dvStg.
                }

                // Half
                if dvHalf > 0 and dvHalf <= dvStg
                {
                    set dvHalfObj[stg] to dvHalf.
                    set dvHalf to 0.
                }
                else if dvHalf > 0 
                {
                    set dvHalfObj[stg] to dvStg.
                    set dvHalf to dvHalf - dvStg.
                }
            }

            if breakFlag break.
        }

        return lex("Full", dvFullObj, "Half", dvHalfObj).
    }
//#endregion



// Available dV Calculations
// #region

    // AvailDV :: () -> <lexicon>
    // Returns a lex of dv available for vessel and per stage
    global function AvailShipDV
    {
        parameter mode is "vac".

        local availDv to 0.
        local dvStgObj to lex().

        from { local stg to stage:number.} until stg < -1 step { set stg to stg - 1.} do 
        {
            set dvStgObj to AvailStageDV(stg, mode).
            set availDv to availDv + dvStgObj[stg].
        }

        set dvStgObj["avail"] to availDv.
        // print "availDv: " + availDv.
        return dvStgObj.
    }

    // AvailStageDV :: (<scalar>) -> <scalar>
    // Returns the calculated deltaV for a given stage
    global function AvailStageDV
    {
        parameter stg, mode is "vac".

        //Problem is in calculating fuel mass in StageMass function
        local stgMass to StageMass(stg).
        local exhVel to GetExhVel(GetEnginesByStage(stg), mode).
        
        //clrDisp(30).
        // print "AvailStageDV".
        // print "stg : " + stg.
        // print "stgMass: " + stgMass.
        // print "exhVel: " + exhVel.
        // Breakpoint().
        local dv to exhVel * ln(stgMass["ship"] / (stgMass["ship"] - stgMass["fuel"])).
        // print "Stg dV: " + dv.
        // print "---".
        return dv.
    }
//#endregion