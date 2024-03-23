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

    global g_SpinStab   to l_SpinStab_Init.
    global g_Spin_Active  to false.
    global g_Spin_Armed   to false.
    global g_Spin_TS      to 0.

    global g_Spin_Act   to { return false.}.
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
            set actDel to { JettisonFairings(_fairings).}.
            set fairingsArmed to true.
        }

        return list(fairingsArmed, chkDel, actDel).
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

        print "Arming spin stabilization" at (0, cr()).
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
                            print "I'm spin checkin!" at (0, cr()).
                            return MissionTime >= __checkVal.
                        }. 
                        return false. 
                    }.
                    set g_Spin_Check to g_Spin_Check:Bind(checkVal).

                    set g_Spin_Act to DoSpinStabilization@:Bind(1):Bind(g_SpinStab:LEADTIME).
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
// #endregion