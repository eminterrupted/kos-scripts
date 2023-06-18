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
  
    // *- Auto Staging
    // #region

    // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
    // Arms automatic staging based on current thrust levels. if they fall below 0.1, we stage
    global function ArmAutoStaging
    {
        parameter _stgLimit to g_StageLimit
                  ,_stgCondition is 0 // 0: ThrustValue < 0.01
                  ,_stgAction is 0.

        local resultCode to 0.
        set g_StageLimit to _stgLimit.
        if Stage:Number <= g_StageLimit 
        {
            set resultCode to 2.
        }
        else
        {
            set g_LoopDelegates["Staging"] to LEX(
                "Check", GetStagingConditionDelegate()
                ,"Action", GetStagingActionDelegate(_stgAction)
            ).

            if g_LoopDelegates:HasKey("Staging") set resultCode to 1.
        }

        return resultCode.
    }
    // #endregion

    // *- Auto Staging Delegates
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
        else if _actionType = 1
        {
            return SafeStageWithUllage@.
        }
    }
        
        
    // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   
    // TODO: Implement other check types here (only thrust value FOR now)
    // Given a staging check type string, performs that condition check and returns the result
    local function GetStagingConditionDelegate
    {
        local condition to CheckShipThrustCondition@.
        local boundCondition to condition:BIND(Ship, 0.01).
        return boundCondition.
    }


    // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> <ResultCode>(Scalar)
    local function CheckShipThrustCondition
    {
        parameter _ves,
                  _checkVal.

        local resultCode to 0.
        if _ves:AvailableThrust < _checkVal and SHIP:STATUS <> "PRELAUNCH" and throttle > 0
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


    // Simpler version of SafeStageWithUllage using new GetEngineFuelStability function
    // TODO: Finish SafeStageWithUllage
    local function SafeStageWithUllage
    {
        local StageResult to false.
        local FuelStabilityMin to 0.975.

        set g_NextEngines to GetNextEngines().
        
        if g_NextEngines:Length > 0 
        {
            if g_NextEngines[0]:Stage < Stage:Number - 1 or not g_NextEngines[0]:Ullage
            {
                set StageResult to true.
            }
            else
            {
                local FuelStability to GetEngineFuelStability(g_NextEngines).
                OutInfo("Fuel Stability Rating (Min/Avg): {0} / {1})":format(round(FuelStability[0], 2), round(FuelStability[1], 2))). 
                
                set StageResult to FuelStability[0] >= FuelStabilityMin. 
            }
        }

        if StageResult
        {
            local RCSResult to RCS. // Stores current RCS state
            set RCS to false. // Disables RCS just before staging in case the stage we drop had RCS ullage. We don't need that slamming back into us as we're building up thrust
            // lock throttle to 0.
            wait until Stage:Ready.
            Stage.
            wait 0.01.
            // lock throttle to t_Val.
            set RCS to rcsResult. // Restores the RCS state to whatever it was before staging.
        }
        return StageResult.
    }
    // #endregion

// #endregion