@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #include "0:/lib/globals.ks"
// #endregion



// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local stagingState to 0.
    local localTS to 0.
    // #endregion

    // *- Global (Adds new globals specific to this library, and updates existing globals)
    // #region
    
    // New entries in global objects
    
    // #endregion
// #endregion



// *~ Functions ~* //
// #region

    // ** Staging
    // #region

        // -- Global
        // #region

        // StagingCheck :: (_program)<Scalar>, (_runmode)<Scalar>, (_checkType)<Scalar> -> (shouldStage)<Bool>
        global function StagingCheck
        {
            parameter _program,
                      _runmode,
                      _checkType is 0.

            if Stage:Number <= g_StageLimit
            {
                return false.
            }
            else
            {
                
            }
        }

        // InitStagingDelegate :: 
        // Adds the proper staging check and action delegates to the g_LoopDelegates object
        global function InitStagingDelegate
        {
            parameter _actionType,
                      _conditionType.

            set g_LoopDelegates["Staging"] to lexicon(
                "Action", GetStagingActionDelegate(_actionType)  // #TODO: Write GetStagingActionDelegate
                ,"Check", GetStagingConditionDelegate(_conditionType)
            ).
        }



        // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. If they fall below 0.1, we stage
        global function ArmAutoStaging
        {
            parameter _stgLimit to g_StageLimit,
                      _stgCondition is 0. // 0: ThrustValue < 0.01

            local resultCode to 0.
            set g_StageLimit to _stgLimit.
            if Stage:Number <= g_StageLimit 
            {
                set resultCode to 2.
            }
            else
            {
                local selectedCondition to GetStagingConditionDelegate(_stgCondition). 

                set g_LoopDelegates["AutoStage"] to lexicon(
                    "Check", selectedCondition
                    ,"Action", SafeStage@
                ).

                if g_LoopDelegates:HasKey("AutoStage") set resultCode to 1.
            }

            return resultCode.
        }
        // #endregion

        // -- Local
        // #region

        // GetStagingActionDelegate :: (_actionType)<Scalar> -> (actionDel)<kOSDelegate>
        // Returns a delegate of the staging function that should be used (via Stage, or directly via a part's ModuleDecoupler action).
        local function GetStagingActionDelegate
        {
            parameter _actionType is 0.

            if _actionType = 0
            {
                return SafeStage@.
            }
        }
        
        
        // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   // TODO: Implement other check types here (only thrust value for now)
        // Given a staging check type string, performs that condition check and returns the result
        local function GetStagingConditionDelegate
        {
            parameter _checkType is 0.

            if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            {
                local condition to CheckShipThrustCondition@.
                local boundCondition to condition:Bind(Ship, 0.01).
                return boundCondition.
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

        local function SafeStage
        {
            wait until Stage:Ready.
            stage.
            wait 0.01.
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting for the stage to report it is ready first
        local function SafeStageState
        {
            local ullageDelegate to { return true. }.

            if stagingState = 0
            {
                wait until Stage:Ready.
                stage.
                set stagingState to 1.
            }
            else if stagingState = 1
            {
                if g_ActiveEngines_Data["Spec"]["IsSepMotor"]
                { 
                    if g_ActiveEngines_Data["Spec"]["Ullage"]
                    {
                        set ullageDelegate to { return CheckUllage(). }.  // #TODO: Write CheckUllage()
                    }
                    set stagingState to 2.
                }
                else
                {
                    set stagingState to 4.
                }
            }
            else if stagingState = 2
            {
                if ullageDelegate:Call()
                {
                    set stagingState to 1.
                }
            }
            else if stagingState = 4
            {
                set stagingState to 0.
                unset ullageDelegate.
                return true.
            }
        }
        // #endregion
    // #endregion
// #endregion