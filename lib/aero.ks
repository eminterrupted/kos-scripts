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
    
    local cdFieldName is "ctrl dflct".
    local farModule is "FARControllableSurface".
    local stdCtrlFieldName is "std. ctrl".
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Aero Event Handling
    // #region
    // NullAeroSurface :: (_aeroObject)<Part|Module> -> (_result)<Bool>
    // Given a FARControllableSurface module (or part containing one), nulls out the std. ctrl values and caches them in the part tag. Returns the resulting part tag.
    global function SetupAeroSurfaceEventHandler
    {
        parameter _execStr to "Ascent".

        local AeroSurfaceModules to Ship:ModulesNamed(farModule).

        local MECO_EngineID_Sets to Lexicon().
        local MECO_EngineID_List to List().
        local resultFlag to False.

        local Current_MECO_ID to 999999.
        
        for m in AeroSurfaceModules 
        { 
            local ecoMET to p:Tag:Split("|")[2]:ToNumber(0).

            if ecoMET > 0 
            {
                if MECO_EngineID_Sets:HasKey(ecoMET)
                {
                    MECO_EngineID_Sets[ecoMET]:Add(p).
                }
                else
                {
                    MECO_EngineID_Sets:Add(ecoMET, list(p)).
                }

                set Current_MECO_ID to Min(Current_MECO_ID, ecoMET).
            }
        }
        
        local MECO_Time    to Current_MECO_ID.

        global MECO_Action_Counter to 0.

        if MECO_Time > 0 
        {
            local checkDel to 
            { 
                parameter _params is list(). 
                
                OutInfo("MECO T-{0}s ":Format(Round(MissionTime - _params[1], 2)), 1). 
                return MissionTime >= _params[1].
            }.

            local actionDel to 
            {
                parameter _params is list(). 
                
                set MECO_Action_Counter to MECO_Action_Counter + 1. 
                
                for eng in Ship:PartsTaggedPattern("Ascent\|MECO\|{0}":Format(_params[1]))
                {
                    if eng:Ignition and not eng:flameout
                    {
                        eng:shutdown.
                        if eng:HasGimbal 
                        {
                            DoAction(eng:Gimbal, "Lock Gimbal", true).
                        }
                        set eng:tag to "".
                    }
                }
                set g_ActiveEngines to GetActiveEngines(ship, "NoBooster").
                set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).
                set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                
                wait 0.01. 

                if Ship:PartsTaggedPattern("^Ascent\|MECO\|\d*(\.\d*)*"):Length > 0
                {
                    UnregisterLoopEvent("MECO").
                    return SetupMECOEventHandler().
                }
                else
                {
                    OutInfo("", 1).
                    set g_MECOArmed to False.
                    return g_MECOArmed.
                }
            }.
                
            local MECO_Event to CreateLoopEvent("MECO", "EngineCutoff", list(MECO_EngineID_List, Current_MECO_ID), checkDel@, actionDel@).
            if RegisterLoopEvent(MECO_Event)
            {
                set resultFlag to True.
                // OutDebug("MECO Handler Created").
            }
        }
        return resultFlag.
    }
    

    // #endregion

    // *- Aero Surface Functions
    // #region

    // NullAeroSurface :: (_aeroObject)<Part|Module> -> (_result)<Bool>
    // Given a FARControllableSurface module (or part containing one), nulls out the std. ctrl values and caches them in the part tag. Returns the resulting part tag.
    global function NullAeroSurface
    {
        parameter _aeroObject.

        local aeroModule is _aeroObject.

        if _aeroObject:IsType("Part")
        {
            set aeroModule to _aeroObject:GetModule(farModule).
        }

        if aeroModule:IsType("PartModule")
        {
            aeroModule:SetField(stdCtrlFieldName, True).
            
            set aeroModule:Part:Tag to "{0}[{1}]":Format(aeroModule:Part:Tag, aeroModule:GetField(cdFieldName)).
            aeroModule:SetField(cdFieldName, 0).
            return True.
        }
        else
        {
            return False.
        }
    }
    // NullShipAeroSurfaces :: (_ves)<Ship> -> (_result)<Bool>
    // Given a vesssel, nulls all FARControllableSurface modules
    global function NullShipAeroSurfaces
    {
        parameter _ves is Ship.

        local failCount to 0.

        for m in _ves:ModulesNamed(farModule)
        {            
            if not NullAeroSurface(m)
            {
                OutMsg("What the crap").
                set failCount to failCount + 1.
            }
        }
        return failCount = 0.
    }


    // RestoreAeroSurface :: (_aeroObject)<Part|Module> -> (_result)<Bool>
    // Given a FARControllableSurface module (or part containing one), restores to cached ctrl dflct value (based on tag; if not present, defaults to 24).
    global function RestoreAeroSurface
    {
        parameter _aeroObject,
                  _newCtrlSrfVal is 24.

        local aeroModule is _aeroObject.

        if _aeroObject:IsType("Part")
        {
            set aeroModule to _aeroObject:GetModule(farModule).
        }
        
        if aeroModule:IsType("PartModule")
        {
            aeroModule:SetField(stdCtrlFieldName, True).
            local fldName to cdFieldName.

            if aeroModule:Part:Tag:MatchesPattern(".*\[\d*\]")
            {
                set _newCtrlSrfVal to aeroModule:Part:Tag:Split("[")[1]:Replace("]",""):ToNumber(_newCtrlSrfVal).
                set aeroModule:Part:Tag to aeroModule:Part:Tag:Split("[")[0].
            }
            aeroModule:SetField(fldName, _newCtrlSrfVal).
            return True.
        }
        else
        {
            return False.
        }
    }
    // RestoreShipAeroSurfaces :: (_ves)<Ship> -> (_result)<Bool>
    // Given a vesssel, restores all FARControllableSurface modules
    global function RestoreShipAeroSurfaces
    {
        parameter _ves is Ship,
                  _newCtrlVal is 24.

        local failCount to 0.

        for m in _ves:ModulesNamed(farModule)
        {            
            if not RestoreAeroSurface(m, _newCtrlVal)
            {
                OutMsg("What the crap").
                set failCount to failCount + 1.
            }
        }
        return failCount = 0.
    }

    // TagAeroSurface
    local function TagAeroSurface
    {
        parameter _aeroObject.

        local aeroModule is _aeroObject.
        local aeroPart   is Ship:RootPart.

        if _aeroObject:IsType("Part")
        {
            set aeroPart to _aeroObject.
            set aeroModule to aeroPart:GetModule(farModule).
        }
        else if aeroModule:IsType("PartModule")
        {
            if not aeroModule:Part:Tag:MatchesPattern(".*\[\d*\]")
            {
                
            }
        }
    }

    // #endregion
// #endregion