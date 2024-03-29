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


// Burn Duration / Stages
// #region

    // TODO: CalcBurnStageData :: _dv<Scalar>, [_startStg<Scalar>] -> BurnStageDataObj<Lexicon>
    global function CalcBurnStageData
    {
        parameter _dvToBurn,
                  _startAtStg.

        local BurnStageDataObj to lexicon(
            "STG", lexicon()
            ,"NEXT", lexicon()
        ).

    //
        // Determine how much dv is available in each stage
        local dv to abs(_dvToBurn).
        local dvHalf to dv / 2.
        local dvFullObj to lex().
        local dvHalfObj to lex().
        local firstPassFlag to True.
        local stageMatchType to 1.

        from { local stg to _startAtStg.} until dv <= 0 or stg = -1 step { set stg to stg - 1.} do {
            local breakFlag to false.
            
            local stgEngs to GetEnginesForStage(stg, "All", stageMatchType).
            local stgMass to GetStageMass2(stg).

            local dvStg to AvailStageDV(stg).
            
            if dvStg > 0 
            {
                // Full
                if dv > dvStg
                {
                    set dvFullObj[stg] to dvStg.
                    set dv to dv - dvStg.
                }
                else
                {
                    set dvFullObj[stg] to dv.
                    set breakFlag to true.
                }

                // Half
                if dvHalf > 0 and dvHalf > dvStg
                {
                    set dvHalfObj[stg] to dvStg.
                    set dvHalf to dvHalf - dvStg.
                }
                else if dvHalf > 0
                {
                    set dvHalfObj[stg] to dvHalf.
                    set dvHalf to 0.
                }
            }

            if breakFlag break.
        }

        local foo to lex("Full", dvFullObj, "Half", dvHalfObj).

        return BurnStageDataObj.
    }




    // CalcBurnDur :: (<scalar>) -> <list>scalar [Full, Half]
    // Returns the time to burn a given dV, including the halfway burn dur for burn start timing
    // Also returns values with staging time included
    global function CalcBurnDur
    {
        parameter dv.

        local stgObj to BurnStagesUsed(dv).
        local durObj to BurnDurStage(stgObj).

        WriteJson(stgObj, "0:/log/{0}_stgObj.json":Format(Ship:Name:Replace(" ","_"))).
        WriteJson(durObj, "0:/log/{0}_durObj.json":Format(Ship:Name:Replace(" ","_"))).
        
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
        
        local burnDurCalcs to list(durObj["Full"], durObj["FullStaged"], durObj["Half"], durObj["HalfStaged"]).

        WriteJson(burnDurCalcs, "0:/log/{0}_burnDurCalcs.json":Format(Ship:Name:Replace(" ","_"))).

        return burnDurCalcs.
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

        for key in dvStgObj:Full:keys
        {
            local stgEngs to GetEnginesForStage(key).
            local stgSpecs to GetEnginesSpecs(stgEngs).
            local exhVel to GetExhVel(stgEngs).
            local stgThr to stgSpecs:StgThrust.
            local vesMass to GetStageMass(key)["ship"].
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
        parameter _dv.

        local dv to abs(_dv).
        local dvHalf to dv / 2.
        local dvFullObj to lex().
        local dvHalfObj to lex().

        from { local stg to stage:number.} until dv <= 0 or stg = -1 step { set stg to stg - 1.} do {
            local breakFlag to false.
            local dvStg to AvailStageDV(stg).
            
            if dvStg > 0 
            {
                // Full
                if dv > dvStg
                {
                    set dvFullObj[stg] to dvStg.
                    set dv to dv - dvStg.
                }
                else
                {
                    set dvFullObj[stg] to dv.
                    set breakFlag to true.
                }

                // Half
                if dvHalf > 0 and dvHalf > dvStg
                {
                    set dvHalfObj[stg] to dvStg.
                    set dvHalf to dvHalf - dvStg.
                }
                else if dvHalf > 0
                {
                    set dvHalfObj[stg] to dvHalf.
                    set dvHalf to 0.
                }
            }

            if breakFlag break.
        }

        return lex("Full", dvFullObj, "Half", dvHalfObj).
    }
//#endregion

// Propellant usage
// #region

    // TODO 
    // GetBurnPropellantUsage :: <lex> -> <lexicon>
    // Given a lex of dv by stage, returns a lex of amount of propellant used by stage
    // global function GetBurnPropellantUsage
    // {
    //     parameter burnStageObj.

    //     local burnProp to 0.

    //     for stg in burnStageObj:keys
    //     {
    //         local stgIsp to GetTotalIsp(GetEnginesByStage(stg)).
    //     }

    // }

// #endregion

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


        local dv to 0.
        local exhVel to 0.
        local stgEngs to GetEnginesForStage(stg).
        local stgMass to Lexicon("Ship", 0 , "Fuel", 0).

        // OutDebug("[AvailStageDV][{0}] stgEngs:":Format(stg, stgEngs:Join(";")), crDbg(2)).

        if stgEngs:Length > 0
        {
            set stgMass to GetStageMass(stg).
            set exhVel to GetExhVel(stgEngs, mode).
            
            if stgMass["Fuel"] > 0
            {
                // OutDebug("[AvailStageDV]({0}) stgMass[ship]: [{1}]":Format(stg, stgMass["ship"]), crDbg()).
                // OutDebug("[AvailStageDV]({0}) stgMass[fuel]: [{1}]":Format(stg, stgMass["fuel"]), crDbg()).
                // OutDebug("[AvailStageDV]({0}) exhVel({1})":Format(stg, exhVel), crDbg()).
                // Breakpoint().
                wait 0.05.
                set dv to exhVel * ln(stgMass["ship"] / (stgMass["ship"] - stgMass["fuel"])).
                // OutDebug("[AvailStageDV]({0}) dv: ":Format(Round(dv, 2)), crDbg()).
            }
            // print "AvailStageDV         ".
            // print "stg : " + stg + "        ".
            // print "stgMass[Ship]: " + stgMass:Ship + "        ".
            // print "stgMass[Fuel]: " + stgMass:Fuel + "        ".
            // print "exhVel: " + exhVel + "        ".
            // Breakpoint().
            // print "Stg dV: " + dv.
            // print "---".
        }

        if g_Debug 
        { 
            // OutDebug("Stage {0}: dV[{1}]   | exhVel[{2}]  ":Format(stg, Round(dv, 2), Round(exhVel, 2)), 10).
            // OutDebug("- stgMass: Ship[{0}] | Fuel[{1}]    ":Format(round(stgMass["Ship"], 3), Round(stgMass["Fuel"], 3)), 11).
            wait 2.5.
        }
        return dv.
    }
//#endregion
    
    // #endregion
// #endregion