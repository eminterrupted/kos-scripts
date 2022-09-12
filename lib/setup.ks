@lazyGlobal off.

// Dependencies
// #include "0:/lib/disp"
// #include "0:/lib/util"
// #include "0:/lib/vessel"

// *~ Variables ~* //
//#region
    // -- Local
    // #region

    // #endregion

    // -- Global
    // #region

    // #endregion
// #endregion

// *~ Functions ~* //
// #region

    // -- Logging
    // #region

    // GetGLogPath :: (none) -> (<path>ToLogfile)
    // 1. Looks in a variety of places for previous existence of a global log file
    //    -- First check is in local cache file
    //    -- If not in cache file, check local vessel starting with core 1, and counting up
    //    -- Checks in 0:/log/<sanitizedMissionName>/<sanitizedMissionName>_mission_<iter>.log
    // 2. If no log file found at any location, call InitGLog 
    global function GetGLogPath
    {
        local doneFlag to false.
        local logPath to "".

        if CheckCacheKey("g_log")
        {
            set logPath to ReadCache("g_log").
        }
        // Now we look for it on the local drives, starting with the volume of the core executing the script
        else 
        {
            local vesVols to buildList("volumes").
            from { local i to 0.} until i >= vesVols:length or doneFlag step { set i to i + 1.} do 
            {
                local vol to vesVol[i].
                if exists(Path(vol:name + ":/log/loc.log"))
                {
                    set logPath to Path(vol:name + ":/log/loc.log").
                }
            }
        }

        if logPath:isType("Path")
        {
            set g_logPath to logPath.
        }
        else
        {
            set g_logPath to InitGLog().
        }

        return g_logPath.
    }


    // InitGLog :: (none) -> (<Path>LogFile)
    // If g_log is not already here, make it
    local function InitGLog
    {
        local logVol to GetLargestVol().
        if logVol <> core:volume set logVol:name to "Log".

    }

    // #endregion

    // Local Functions
    // #region

    local function GetLevelFiles
    {
        parameter volDir is core:volume:root,
                  volLevel is 0.

        if volDir:HasSuffix("Lex")
        {
            local levelFiles to list().
            local levelDirs to lex().
            local lvlIdx to 0.
            local lvlContent to volDir:Lex:Values.

            until false
            {
                for vi in lvlContent.
                {
                    if vi:IsFile and lvlIdx = volLevel or volLevel < 0
                    {
                        levelFiles:Add(vi).
                    }
                    else if vi:HasSuffix("Lex")
                    {
                        levelDirs:Add(vi).
                    }
                }

                if levelDirs:Length = 0 or lvlIdx = volLevel
                {
                    break.
                }
                else
                {
                    break.
                }
            }
        }
    }

    local function GetDirFiles 
    {
        parameter volDir is core:volume:root.

        local dirFiles to volDir:lex:values.

        return dirFiles.
    }

    local function GetLevelDirs
    {
        parameter volDir is core:volume:root,
                  volLvl is 0.

        local lvlDirs to list().

        if volDir:HasSuffix("Lex")
        {
            local doneFlag to false.
            local volDirContent to volDir:lex.

            from { local lvl to 0.} until lvl >= volLvl or doneFlag step { set lvl to lvl + 1.} do 
            {
                if volLvl < 0 or lvl = volLvl
                {
                    for vi in volDirContent:values 
                    {
                        if vi:HasSuffix("Lex") 
                        {
                            lvlDirs:add(vi).
                        }
                    }
                    if lvl = volLvl 
                    {
                        set doneFlag to true.
                    }
                    else if lvlDirs:length = 0 
                    {
                        set doneFlag to true.
                    }
                }
            }
        }
        return lvlDirs.
    }

    local function CheckVolDepth
    {
        parameter vol.

        local lvl to 0.
        local lvlDir to list(vol:root).
        local maxLvl to 0.
        local nextLvlDir to list().

        until lvlDir:length = 0
        {
            for vi in lvlDir:lex:values
            {
                if vi:hasSuffix("Lex")
                {
                    nextLvlDir:add(vi).
                }
            }
            
            set lvlDir to nextLvlDir.
            nextLvlDir:Clear().
            set maxLvl to max(lvl, maxLvl).
        }

        return maxLvl.
    }

    local function GetLargestVol
    {
        local allVols to BuildList("volumes").
        local maxVol to allVols[allVols:length - 1].
        
        from { local i to allVols:length - 1.} until i < 1 step { set i to i - 1.} do 
        {
            local vol to allVols[i].
            if vol:freeSpace >= 1024 and vol:freeSpace > maxVol:freeSpace
            {
                set maxVol to vol.
            }
        }
        return maxVol.
    }

    local function GetBestVols
    {
        local allVols   to BuildList("volumes").
        local maxVol    to allVols[allVols:length - 1].
        local effIVol   to maxVol.
        local effLVol   to maxVol.
        local volPower  to { parameter vol. for cpu in g_cpus { if cpu:volume = vol { return cpu:getField("kos average power").}} return 99999.}.
        local effLVal   to effLVol:powerRequirement + volPower(effLVol).
        
        from { local i to allVols:length - 1.} until i < 1 step { set i to i - 1.} do
        {
            local vol to allVols[i].
            if vol:freeSpace > maxVol:freeSpace
            {
                set maxVol to vol.
            }
            if vol:powerRequirement < effIVol:powerRequirement
            {
                set effIVol to vol.
            } 
            if vol:powerRequirement + volPower(vol) < effLVal
            {
                set effLVol to vol.
                set effLVal to vol:powerRequirement + volPower(vol).
            }
        }

        return lex("maxVol", maxVol, "iPwrVol", effIVol, "lPwrVol", effLVol).
    }

    global function GetBestCores
    {
        local maxSize   to g_cpus[g_cpus:length - 1].
        local cPwrComb  to maxSize.
        local cPwrIdle  to maxSize.
        local cPwrLoad  to maxSize.
        
        from { local i to g_cpus:length - 1.} until i < 1 step { set i to i - 1.} do
        {
            local cpu to g_cpus[i].
            
            if cpu:volume:freeSpace > maxSize:volume:freeSpace
            {
                set maxSize to cpu.
            }
            if cpu:volume:powerRequirement < cPwrIdle:volume:powerRequirement
            {
                set cPwrIdle to cpu.
            }
            if cpu:getField("kos average power") < cPwrLoad:getField("kos average power")
            {
                set cPwrLoad to cpu.
            } 
            if cpu:volume:powerRequirement + cpu:getField("kos average power") < cPwrLoad:volume:powerRequirement + cPwrLoad:getfield("kos average power")
            {
                set cPwrComb to cpu.
            }
        }

        return lex("maxSize", maxSize, "cPwrComb", cPwrComb, "cPwrIdle", cPwrIdle, "cPwrLoad", cPwrLoad).
    }

    // #endregion
//#endregion