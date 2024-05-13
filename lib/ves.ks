// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_LESJettisonAlt to 88000.
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

    global g_VesSpecs to GetVesselStageSpecs("1000").

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

        if not _antModules:IsType("List")
        {
            set _antModules to list(_antModules).
        }

        for m in _antModules
        {
            DoEvent(m, "extend antenna").
        }
    }

    // Launch Escape System
    global function ArmLESJettison
    {
        parameter _les to core:part.

        local lesList to list().

        if _les:IsType("Part")
        {
            if _les:uid = core:part:uid
            {
                for p in Ship:PartsDubbedPattern("(.*LES.*|Launch.*Escape)")
                {
                    lesList:Add(p).
                }
            }
        }
        else if _les:IsType("List")
        {
            set lesList to _les.
        }

        local lesCheck to { parameter __checkVal. return Ship:Altitude > __checkVal.}.

        return list(lesList:Length > 0, lesCheck@:Bind(l_LESJettisonAlt), JettisonLES@:Bind(lesList)).
    }

    local function JettisonLES
    {
        parameter _lesList.

        for p in _lesList
        {
            p:activate.
            if p:HasModule("ModuleDecouple")
            {
                local m to p:GetModule("ModuleDecouple").
                m:DoEvent("decouple").
            }
        }
        return false.
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


    // ArmMECO
    //
    global function ArmMECO
    {
        parameter _MEList is Ship:PartsTaggedPattern("Ascent\|MECO.*").

        local MECOArmed to false.
        local chkDel to { return true. }.
        local actDel to { return false. }.

        if _MEList:Length > 0
        {
            local chkSec to 999.
            local tagParts to _MEList[0]:Tag:Split("|").
            
            if tagParts:length > 2
            {
                set chkSec to ParseStringScalar(tagParts[2], chkSec).
            }

            set chkDel to { return MissionTime >= chkSec.}.
            set actDel to { 
                parameter __MEList.

                for eng in __MEList
                {
                    if eng:Ignition and not eng:Flameout
                    {
                        eng:Shutdown.
                    }
                }

                for p in Ship:PartsTaggedPattern("AS\|MECO")
                {
                    if p:IsType("Engine")
                    {
                        p:Activate.
                    }
                }

                for p in Ship:PartsTaggedPattern("DC\|MECO")
                {
                    if p:HasModule("ProceduralFairingDecoupler")
                    {
                        local m to p:GetModule("ProceduralFairingDecoupler").
                        DoEvent(m, "jettison fairing").
                        // {
                        //     DoAction(m, "jettison fairing", true).
                        // }
                    }
                    else if p:HasModule("ModuleDecouple")
                    {
                        local m to p:GetModule("ModuleDecouple").
                        DoEvent(m, "decouple").
                        // {
                        //     DoAction(m, "decouple", true).
                        // }
                    }
                }
                set g_ActiveEngines to GetActiveEngines().

                return Ship:PartsTaggedPattern("MECO"):Length > 0.
            }.
            set actDel to actDel@:Bind(_MEList).

            set MECOArmed to true.
        }

        return list(MECOArmed, chkDel, actDel).
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
        parameter _stgLimit is g_StageLimit,
                  _rollFactor to 1.

        local spinStages to GetSpinStages(_stgLimit).

        OutMsg("Arming spin stabilization", cr()).
        OutLog("Running ArmSpinStabilization subroutine").
        from { local stg to Stage:Number - 1.} until stg < _stgLimit or g_Spin_Armed step { set stg to stg - 1.} do
        {
            if spinStages:HasKey(stg)
            {
                // OutLog("Stage Hit: {0}":Format(stg), 1).
                set g_SpinStab to spinStages[stg].
                set g_Spin_Check to { 
                    parameter __checkStg,
                            __checkVal,
                            __curVal.

                    local curStgChk to Stage:Number - 1.

                    if curStgChk = __checkStg
                    {
                        // OutInfo("g_Spin_Check[PASS]: [{0}] <= [{1}]":Format(__curVal, __checkVal)).
                        return __curVal <= __checkVal.
                    }
                    else if curStgChk > __checkStg
                    {
                        // OutStr("g_Spin_Check[FAIL]: [{0}] = [{1}]":Format(curStgChk, __checkStg), Terminal:Height - 11).
                    }
                    else
                    {
                        // clr(Terminal:Height - 11).
                        set g_Spin_Armed to False.
                    }
                    return false. 
                }.
                set g_Spin_Check to g_Spin_Check:Bind(stg):Bind(g_SpinStab:LEADTIME).

                set g_Spin_Action to DoSpinStabilization@:Bind(_rollFactor):Bind(stg).
                set g_Spin_Armed to True.
                return g_Spin_Armed.
            }
            else
            {
                OutLog("Stage : {0}":Format(stg), 1).
            }
        }
    }


    // DoSpinStabilization ::
    //
    local function DoSpinStabilization
    {
        parameter _rollVal,
                  _stpStg.
                  //_leadTime.
        
        OutInfo("DoSpinStabilization").

        if g_Spin_Active
        {
            if Stage:Number <= _stpStg
            {
                set Ship:Control:Roll to 0.
                set g_Spin_Active to false.
                set g_Spin_Armed to false.
                ClearScreen.
            }
            else
            {
                // OutInfo("Stage:Number [{0}] <= [{1}] _stpStg":Format(Stage:Number, _stpStg)).
            }
        }
        else
        {
            set g_Steer to g_Steer:Vector.
            set Ship:Control:Roll to _rollVal.
            // set g_Spin_TS to Time:Seconds + _leadtime.
            set g_Spin_Active to true.
            OutInfo("SpinActive!").
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
                    local leadTime to l_SpinMin.
                    if p:Tag:MatchesPattern("SpinDC\|\d*")
                    {
                        local tagSpl to p:Tag:Split("|").
                        set leadTime to tagSpl[tagSpl:Length - 1]:ToNumber(leadTime).
                    }
                    spinStages:Add(p:Stage, lex(
                        "ARMED", false
                        ,"LEADTIME", leadTime
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

    // GetVesselStageSpecs
    global function GetVesselStageSpecs
    {
        parameter _bitMask is "1000". // [1]000 = Stage Mass
                                      // 0[1]00 = Fuel Mass
                                      // 00[0]0 = (Reserved)
                                      // 000[0] = (Reserved)

        local vesLex to lex(
            "ShipMass", lex(),
            "FuelMass", lex()
        ).

        for p in ship:parts
        {
            if _bitMask[0]
            {
                if vesLex:ShipMass:HasKey(p:DecoupledIn)
                {
                    set vesLex["ShipMass"][p:DecoupledIn] to vesLex["ShipMass"][p:DecoupledIn] + p:Mass.
                }
                else
                {
                    vesLex:ShipMass:Add(p:DecoupledIn, p:Mass).
                }
            }
        }

        return vesLex.
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

            local engResidual to choose eng:GetModule("ModuleEnginesRF"):GetField("predicted residuals") if eng:HasModule("ModuleEnginesRF") else 0.
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