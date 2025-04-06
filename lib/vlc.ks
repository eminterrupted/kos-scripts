@LazyGlobal off.

// Vehicle Launch Control

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region

    // #endregion

    // *- Delegates
    // #region

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Launchpad functions
    // #region
    
    // get_pad_stage :: ([_startStg<int>]) -> padStage<Int>
    // Returns the stage number of the launch pad/clamps
    global function get_pad_stage
    {
        parameter _startStg is stage:Number.

        local padStage to _startStg.
        for m in ship:ModulesNamed("LaunchClamp")
        { 
            set padStage to min(padStage, m:Part:Stage).
        }
        return padStage.
    }
    
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
    // #endregion

// #endregion