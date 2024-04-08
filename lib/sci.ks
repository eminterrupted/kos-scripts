// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
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


// *~ Functions ~* //
// #region
    // *- Experiment parsing
    // #region
    // GetValidExperiments :: (_part)<Part> -> (validExperiements)<Lexicon>
    // Given a part with Experiment modules, returns the ones that are currently active
    // **NOTE** : Due to a limitation between KSP and kOS, the part's PAW window must be 
    //            opened before this function can see active experiements
    global function GetValidExperiments
    {
        parameter _part.

        local expObj to lexicon().

        for exp in _part:ModulesNamed("Experiment")
        {
             if exp:AllEvents[0] <> "(callable) _, is KSPEvent"
             {
                local expAction to GetKSPActionFromExperiment(exp:AllEvents[0]).
                if not expAction[1]:Contains("running") and expAction[1]:Length > 0
                {
                    set expObj[expAction[0]] to list(exp, expAction[1]).
                }
             }
        }
        
        return expObj.
    }

    // GetKSPActionFromExperiment :: _string<String> -> list(expName<String>, expAction<ModuleAction>)
    global function GetKSPActionFromExperiment
    {
        parameter _string.

        local expName to "".
        local expAction to "".

        local stringSplit to _string:Split("<b>").
        if stringSplit:Length > 1 {
        set expName to stringSplit[1]:Substring(0, stringSplit[1]:Find("<")).
        set expAction to _string:Replace("(callable) ",""):Replace(", is KSPAction").
        }
        return list(expName, expAction).
    }
    // #endregion

    // *- Data transfer
    // #region

    // GetDataDrive :: [_dataPart<Part>] -> dataDrive<Module>
    // Returns a HardDrive module for a given part; falls back to root core if no part provided
    global function GetDataDrive
    {
        parameter _dataPart to "".

        local dataDrive to "".

        if _dataPart:IsType("String")
        {
            if Core:Part:HasModule("HardDrive")
            {
                set dataDrive to Core:Part:GetModule("HardDrive").
            }
        }
        else if _dataPart:HasModule("HardDrive")
        {
            set dataDrive to Core:Part:GetModule("HardDrive").
        }
        
        return dataDrive.
    }

    // TransferSciData :: [_tgtDrive<Part>]
    global function TransferSciData
    {
        parameter _tgtDrivePart is "".

        local result to False.
        
        OutMsg("Checking Science Data").
        
        if _tgtDrivePart:IsType("String") 
        {
            if ship:partsNamed("RP0-SampleReturnCapsule"):Length > 0  // If we have a proper sample return capsule, use it
            {
                set _tgtDrivePart to GetDataDrive(ship:PartsNamed("RP0-SampleReturnCapsule")[0]).
                DoEvent(_tgtDrivePart:GetModule("ModuleAnimateGeneric"), "Close"). // Close the door if open
            }
            else 
            {
                set _tgtDrivePart to Core:Part.
            }
        }
        local sciDrive to GetDataDrive(_tgtDrivePart).

        if sciDrive:IsType("String")
        {
            OutMsg("No HDD for data collection").
        }
        else
        {
            OutMsg("Collecting Data").
            set result to DoEvent(sciDrive, "transfer data here").
            if not result set result to DoAction(sciDrive, "transfer data here").
        }

        // if g_Debug OutDebug("Exiting TransferSciData with result: [{0}]":Format(result)).
        return result.
    }
    //#endregion
// #endregion