// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_SpinMin to 12.
    local l_SpinStab_Init to lex("ARMED", false, "LEADTIME", 0, "STG", -1).

    // #endregion

    // *- Global
    // #region
    global g_Steer to Ship:Facing.
    global g_Throt to 0.
    
    global g_SpinStab   to l_SpinStab_Init.
    global g_Spin_Active  to false.
    global g_Spin_Armed   to false.
    global g_Spin_TS      to 0.

    global g_Spin_Action   to { return false.}.
    global g_Spin_Check to { return false.}.
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

//  *- Part Module Helpers
// #region

    // Antenna
    // #region
    global function ArmAntennaDeploy
    {
        local antCheck  to { return HomeConnection:IsConnected().}.
        local antAction to DeployAntenna@.

        return list(antCheck@, antAction).
    }

    global function DeployAntenna
    {
        parameter _antModules is Ship:ModulesNamed("ModuleDeployableAntenna").

        for m in _antModules
        {
            DoEvent(m, "extend antenna").
        }
    }

    // #endregion

    // ArmFairingJettison
    //
    global function ArmFairingJettison
    {
        parameter _fairings is Ship:PartsTaggedPattern("Fairing").

        local fairingsArmed to false.
        local chkDel to { return true. }.
        local actDel to { return false. }.

        if _fairings:Length > 0
        {
            local chkAlt to 100000.
            local tagParts to _fairings[0]:Tag:Split("|").
            if tagParts:length > 2
            {
                set chkAlt to ParseStringScalar(tagParts[2], chkAlt).
            }

            set chkDel to { return Ship:Altitude >= chkAlt.}.
            set actDel to { JettisonFairings(_fairings). return false.}.
            set fairingsArmed to true.
        }

        return list(fairingsArmed, chkDel, actDel).
    }



    global function DeploySolarPanels
    {
        for m in Ship:ModulesNamed("ModuleROSolar") { DoEvent(m, "extend solar panel").}.
    }

    // JettisonFairings :: 
    // Accepts a list of either fairing parts or part modules 
    global function JettisonFairings
    {
        parameter _fairings.

        for f in _fairings
        {
            if f:IsType("Part") { set f to f:GETMODULE("ProceduralFairingDecoupler"). }
            DoEvent(f, "jettison fairing").
        }
    }


// #endregion

//  *- Spin Stabilization
// #region

    // ArmSpinStabilization :: 
    // 
    global function ArmSpinStabilization
    {
        parameter _stgLimit is g_StageLimit.

        local spinStages to GetSpinStages(_stgLimit).

        OutMsg("Arming spin stabilization", cr()).
        from { local stg to Stage:Number.} until stg < _stgLimit step { set stg to stg - 1.} do
        {
            if spinStages:HasKey(stg)
            {
                set g_SpinStab to spinStages[stg].
                from { local i to stg.} until i > Stage:Number step { set i to i + 1.} do
                {
                    local bt to choose g_ShipEngines[stg + 1]:TARGETBURNTIME if g_ShipEngines:HasKey(stg + 1) else -1.
                    local checkVal to MissionTime + bt - g_SpinStab:LEADTIME.

                    set g_Spin_Check to { 
                        parameter __checkVal. 
                        if g_SpinStab:STG = Stage:Number - 1 
                        {
                            return MissionTime >= __checkVal.
                        }. 
                        return false. 
                    }.
                    set g_Spin_Check to g_Spin_Check:Bind(checkVal).

                    set g_Spin_Action to DoSpinStabilization@:Bind(1):Bind(g_SpinStab:LEADTIME).
                    set g_Spin_Armed to True.
                }.
            }
        }

    }


    // DoSpinStabilization ::
    //
    local function DoSpinStabilization
    {
        parameter _rollVal,
                  _leadTime.
        
        if g_Spin_Active
        {
            if Time:Seconds >= g_Spin_TS
            {
                set Ship:Control:Roll to 0.
                set g_Spin_Active to false.
                set g_Spin_Armed to false.
            }
        }
        else
        {
            set g_Steer to g_Steer:Vector.
            set Ship:Control:Roll to _rollVal.
            set g_Spin_TS to Time:Seconds + _leadtime.
            set g_Spin_Active to true.
        }
    }

    // GetSpinStages ::
    //
    global function GetSpinStages
    {
        parameter _stgLimit.

        local spinStages to lex().
        for p in Ship:PartsTaggedPattern("SpinDC")
        {
            if p:Stage >= _stgLimit
            {
                if not spinStages:HasKey(p:Stage)
                {
                    spinStages:Add(p:Stage, lex(
                        "ARMED", false
                        ,"LEADTIME", l_SpinMin
                        ,"STG", p:Stage
                    )).
                }
            }
        }
        return spinStages.
    }
    
// #endregion

// Vessel Stage Data
// #region

    // GetEnginesDC
    //
    // GetEnginesDC :: _engList<List> -> bestDC<Decoupler>
    global function GetEnginesDC
    {
        parameter _engList.

        local minDCStg to Stage:Number.
        local bestDC to "".
        
        for eng in _engList
        {
            if eng:DecoupledIn < minDCStg
            {
                set minDCStg to eng:DecoupledIn.
                set bestDC to eng:Decoupler.
            }
        }
        return bestDC.
    }

    // StageMass :: (<scalar>) -> <lexicon>
    // Returns a lex containing mass statistics for a given stage number
    global function GetStageMass
    {
        parameter stg.

        local stgMass to 0.

        //ISSUE: stgFuelMass appears to be about half (or at least, lower than) 
        //what it should be
        local stgFlowMass to 0.
        local stgFuelMass to 0.
        local stgFuelUsableMass to 0.
        local stgResidual to 0.
        local stgShipMass to 0.
        local totalResFlow to 0.
        
        local stgEngs    to GetStageEngines(stg). // choose g_ShipEngines:IGNSTG[stg]:ENG if g_ShipEngines:IGNSTG:HasKey(stg) else list().
        local stgDC      to GetEnginesDC(stgEngs).
        local nextDCStg  to choose stgDC:Stage if stgDC:IsType("Decoupler") else -1.
        local nextEngStg to stg - 1.
        from { local i to nextEngStg.} until i <= 0 step { set i to i - 1.} do
        {
            if g_ShipEngines:IGNSTG:HasKey(i) set nextEngStg to i.
        }
        

        local engResUsed to lexicon(
            "RSRC", list()
            ,"RSDL", list()
            ,"FLOW", list()
        ).

        for eng in stgEngs {
            engResUsed:FLOW:Add(eng:MaxMassFlow).
            set stgFlowMass to stgFlowMass + eng:MaxMassFlow.

            local m to eng:GetModule("ModuleEnginesRF").
            local engResidual to m:GetField("predicted residuals").
            engResUsed:RSDL:Add(engResidual).

            for k in eng:ConsumedResources:Keys 
            {
                if not engResUsed:RSRC:Contains(k) engResUsed:RSRC:Add(k:replace(" ", "")).
            }
        }
        
        from { local i to 0.} until i >= engResUsed:RSDL:Length step { set i to i + 1.} do {
            local rsdl to engResUsed:RSDL[i].
            local flow to engResUsed:FLOW[i].
            local flowRes    to flow * (1 - rsdl).
            set totalResFlow to totalResFlow + flowRes.
        }
        set stgResidual to (stgFlowMass - totalResFlow) / stgFlowMass.

        // OutDebug("[GetStageMass][{0}] engResUsed:RSRC [{1}]":Format(stg, engResUsed:RSRC:Join(";")), crDbg()).

        for p in Ship:parts
        {
            // OutDebug("[GetStageMass][{0}] Processing part: [{1}]":Format(stg, p), crDbg()).
            if p:typeName = "Decoupler" 
            {
                if p:Stage <= stg set stgShipMass to stgShipMass + p:Mass.
                if p:Stage = stg set stgMass to stgMass + p:Mass.
                // OutDebug("[GetStageMass][{0}] Part is decoupler":Format(stg), crDbg()).
            }
            else if p:DecoupledIn <= stg
            {
                // OutDebug("[GetStageMass][{0}] Part <= stg":Format(stg), crDbg()).
                set stgShipMass to stgShipMass + p:Mass.
                if p:DecoupledIn >= nextDCStg // p:Stg <= stg and p:DecoupledIn >= nextDCStg and p:Stage <= stg // >= nextDCStg and p:DecoupledIn <= stg
                {
                    set stgMass to stgMass + p:Mass.
                }
            }

            if p:DecoupledIn <= stg and p:DecoupledIn >= nextDCStg and p:Resources:Length > 0 
            {
                for res in p:Resources
                {
                    if engResUsed:RSRC:Contains(res:Name) 
                    {
                        // print "Calculating: " + res:Name.
                        set stgFuelMass to stgFuelMass + (res:amount * res:density).
                    }
                }
                set stgFuelUsableMass to stgFuelMass * (1 - stgResidual).
            }
        }

        return lex("stage", stgMass, "fuel", stgFuelMass, "fuelActual", stgFuelUsableMass, "ship", stgShipMass).
    }

// #endregion
// #endregion