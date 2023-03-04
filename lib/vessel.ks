@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #include "0:/lib/globals.ks"
// #endregion



// *~ Variables ~* //
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global (Adds new globals specific to this library, and updates existing globals)
    // #region
    
    // New entries in global objects
    // This adds engines to the part info global
    set g_PartInfo["Engines"] to lexicon( 
        "SEPREF", list(
            "ROSmallSpinMotor" // Spin Sepratron
        )
    ).

    // #endregion
// #endregion



// *~ Functions ~* //
// #region

    // ** Staging
    // #region

        // -- Global
        // #region

        // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. If they fall below 0.1, we stage
        global function ArmAutoStaging
        {
            parameter _stgLimit to 0,
                      _stgCondition is 0. // 0: ThrustValue < 0.01

            local resultCode to 0.
            local selectedCondition to GetStageConditionDelegate(_stgCondition). 

            set g_LoopDelegates["AutoStageCheck"] to lexicon(
                "Check", selectedCondition
                ,"Exec", SafeStage@
            ).

            if g_LoopDelegates:HasKey("AutoStageCheck") set resultCode to 1.

            return resultCode.
        }
        // #endregion

        // -- Local
        // #region
        // CheckStageCondition :: (_checkType)<string> -> (Result)<bool>   // TODO: Implement other check types here (only thrust value for now)
        // Given a staging check type string, performs that condition check and returns the result
        local function GetStageConditionDelegate
        {
            parameter _checkType.

            if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            {
                return CheckShipThrustCondition:Bind(Ship, 0.01)@.
            }
            // else if _checkType = 1
            // {

            // }
        }


        // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> <ResultCode>(Scalar)
        local function CheckShipThrustCondition
        {
            parameter _ves, 
                      _checkVal.

            local resultCode to 0.
            if _ves:AvailableThrust < _checkVal
            {
                set resultCode to 1.
            }

            return resultCode.
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting for the stage to report it is ready first
        local function SafeStage
        {
            wait until Stage:Ready.
            Stage.
            Wait 0.01.
        }
        // #endregion
    // #endregion
// #endregion