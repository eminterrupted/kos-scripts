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
                  mnvBody is ship:body.

        local dv1 to 0. // First transfer burn, boost up to xfrAp
        local dv2 to 0. // Second transfer burn at xfrAp to tgtPe
        local dv3 to 0. // Circularization to tgtAp

        // Orbiting radii for initial, target, and transfer orbits
        local r1  to stPe + mnvBody:radius.
        local r2  to tgtPe + mnvBody:radius.
        local rB  to xfrAp + mnvBody:radius.

        // Semimajor-axis for transfer 1 and 2
        local a1 to (r1 + rb) / 2.
        local a2 to (r2 + rb) / 2.

        set dv1 to sqrt(((2 * mnvBody:mu) / r1) - (mnvBody:mu / a1)) - sqrt(mnvBody:mu / r1).
        set dv2 to sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a2)) - sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a1)).
        set dv3 to sqrt(((2 * mnvBody:mu) / r2) - (mnvBody:mu / a2)) - sqrt(mnvBody:mu / r2).

        return list(dv1, dv2, dv3).
    }
//#endregion


// Burn Duration / Stages
// #region

    // BurnDur :: (<scalar>) -> <list>scalar [Full, Half]
    // Returns the time to burn a given dV, including the halfway burn dur for burn start timing
    global function BurnDur
    {
        parameter dv.

        local stgObj to BurnStagesUsed(dv).
        //print stgObj.
        local durObj to BurnDurStage(stgObj).
        
        return list(durObj["Full"], durObj["Half"]).
    }

    // BurnDurStage :: (<lexicon>) -> <lexicon>
    // Returns the time in secs to burn the dv defined by the result of BurnStagesUsed
    local function BurnDurStage
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

            // print "final dur params".
            // print "exhVel[" + (key) + "]: " + exhVel.
            // print "stgThr[" + (key) + "]: " + stgThr.
            // print "vesMass[" + key + "]:" + vesMass.
            // print " ".
            // print " ".

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
    local function BurnStagesUsed
    {
        parameter dv.

        set dv to abs(dv).
        local dvHalf to dv / 2.
        local dvFullObj to lex().
        local dvHalfObj to lex().

        from { local stg to stage:number.} until dv <= 0 or stg < 0 step { set stg to stg - 1.} do {
            local breakFlag to false.
            // print "In the loop with stage: " + stg.
            local dvStg to AvailStageDV(stg).
            // print "AvailStageDV Return: " + dvStg.
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
        local availDv to 0.
        local dvStgObj to lex().

        from { local stg to stage:number.} until stg < 0 step { set stg to stg - 1.} do 
        {
            set dvStgObj to AvailStageDV(stg).
            set availDv to availDv + dvStgObj[stg].
        }

        set dvStgObj["avail"] to availDv.
        return dvStgObj.
    }

    // AvailStageDV :: (<scalar>) -> <scalar>
    // Returns the calculated deltaV for a given stage
    global function AvailStageDV
    {
        parameter stg.

        // print "AvailStageDV".
        local stgMass to StageMass(stg).
        // print "stgMass: " + stgMass.
        local exhVel to GetExhVel(GetEnginesByStage(stg)).
        // print "exhVel: " + exhVel.

        return exhVel * ln(stgMass["ship"] / (stgMass["ship"] - stgMass["fuel"])).
    }
//#endregion