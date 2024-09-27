// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
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
    // *- Experiment execution
    // #region

    // DeployExperiment
    global function DeployExperiment
    {
        parameter _part,
                _actionIdx is 1,
                _experimentType is "all".

        local _actionStr to choose "stop" if _actionIdx = 0 else choose "start" if _actionIdx = 1 else "".
        if _experimentType <> "all"
        {
            set _actionStr to "{0}: {1}":format(_actionStr, _experimentType).
        }

        if _actionStr:Length > 0
        {
            from { local mIdx to 0.} until mIdx = _part:Modules:Length step { set mIdx to mIdx + 1.} do
            {
                local m to _part:GetModuleByIndex(mIdx).
                if m:Name = "Experiment"
                {
                    for a in m:AllActionNames
                    {
                        if a:Contains(_actionStr)
                        {
                            DoAction(m, a).
                            wait 0.25.
                        }
                    }
                }
            }
        }
    }

    // DoExperiment
    global function DoExperiment
    {
        parameter _part,
                _actionIdx is 1,
                _experimentType is "all".

        local _actionStr to choose "stop" if _actionIdx = 0 else choose "start" if _actionIdx = 1 else "".
        if _experimentType <> "all"
        {
            set _actionStr to "{0}: {1}":format(_actionStr, _experimentType).
        }

        if _actionStr:Length > 0
        {
            from { local mIdx to 0.} until mIdx = _part:Modules:Length step { set mIdx to mIdx + 1.} do
            {
                local m to _part:GetModuleByIndex(mIdx).
                if m:Name = "Experiment"
                {
                    for a in m:AllActionNames
                    {
                        if a:Contains(_actionStr)
                        {
                            DoAction(m, a).
                            wait 0.25.
                        }
                    }
                }
            }
        }
    }

    // #endregion


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

        if not sciDrive:IsType("String")
        {
            OutMsg("Collecting Data").
            set result to DoEvent(sciDrive, "transfer data here").
        }
        else
        {
            OutMsg("No HDD for data collection").
        }

        if g_Debug OutDebug("Exiting TransferSciData with result: [{0}]":Format(result)).
        return result.
    }
    //#endregion
// #endregion