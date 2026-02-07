// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion

// References
    // [1] MODULE(FARControllableSurface)
    //     [ 0] = ["value"] = "(settable) pitch %, is Single"
    //     [ 1] = ["value"] = "(settable) yaw %, is Single"
    //     [ 2] = ["value"] = "(settable) roll %, is Single"
    //     [ 3] = ["value"] = "(settable) aoa %, is Single"
    //     [ 4] = ["value"] = "(settable) brakerudder %, is Single"
    //     [ 5] = ["value"] = "(settable) ctrl dflct, is Single"
    //     [ 6] = ["value"] = "(settable) flp/splr, is Boolean"
    //     [ 7] = ["value"] = "(settable) std. ctrl, is Boolean"
    //     [ 8] = ["value"] = "(settable) dynamic deflection, is Boolean"
    //     [ 9] = ["value"] = "(settable) stalled %, is Double"
    //     [10] = ["value"] = "(callable) activate spoiler, is KSPAction"
    //     [11] = ["value"] = "(callable) increase flap deflection, is KSPAction"
    //     [12] = ["value"] = "(callable) decrease flap deflection, is KSPAction"

// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    local __FARCtrlSrfModule is "FARControllableSurface".

    local __AeroModules is lexicon(
        __FARCtrlSrfModule, lex(
            "f", lex(
                "flpsplctrl",lex(
                    "_",    list("flp/splr")
                    ,"flp", list("flap", list("Boolean"))
                    ,"spl", list("spoiler", list("Boolean"))
                    ,"dfl", list("flp/splr dflct", list("Double", -40, 40))
                )
                ,"stdctrl", lex(
                    "_",    list("std. ctrl")
                    ,"dfl", list("ctrl dflct", list("Single", -40, 40))
                    ,"pit", list("pitch %", list("Double", -100, 100))
                    ,"yaw", list("yaw %", list("Double", -100, 100))
                    ,"rol", list("roll %", list("Double", -100, 100))
                    ,"aoa", list("aoa %", list("Double", -200, 200))
                    ,"brdr",list("brakerudder %", list("Double", -100, 100))
                )
                ,"dyndflct",  lex(
                    "_",    list("dynamic deflection")
                    ,"tgl", list("toggle dyanmic deflection", list("Boolean"))
                    ,"spd", list("start speed", list("Single", 0, 1000))
                    ,"exp", list("reduction exponent", list("Single", 0, 4))
                    ,"min", list("minimal control", list("Single", 0, 1))
                )
                ,"Delegates", lex(
                    "GETF",   { parameter _mod, _key, _fbval is false.          if _mod:HasField(_key) {                               return _mod:GetField(_key).} else { return _fbval.} }
                    ,"OPENF", { parameter _mod, _key.                           if _mod:HasField(_key) { _mod:SetField(_key, true).    return _mod:GetField(_key).}        return false.   }
                    ,"SETF",  { parameter _mod, _key, _tgtval, _fbval is false. if _mod:HasField(_key) { _mod:SetField(_key, _tgtval). return _mod:GetField(_key).}        return _fbVal.  }
                )
            )
            ,"e", lex()
            ,"a", lex()
        )
    ).
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion

// *~ Functions ~* //
// #region
  
    // *- Aero Event Handling
    // #region
    // #TODO SetupAeroSurfaceEventHandler :: (_aeroObject)<Part|Module> -> (_result)<Bool>
    // Sets up an event handler for control surfaces
    // global function SetupAeroSurfaceEventHandler
    // {
    //     parameter _execStr to "Ascent".

    //     // local AeroSurfaceModules to Ship:ModulesNamed(__farModule).
    //     local checkDel to  {}.
    //     local actionDel to  {}.

    //     local ControlPartsObj to lexicon().        
    //     local TaggedParts to Ship:PartsTaggedPattern(_execStr + "\|((FAR)?Aero|Ctrl)\|.*\|.*"). // 4 Tag nibbles: Ascent|FARAero|DFL:22|StgIgn
    //     local commonParts to lexicon().

    //     local eventParams to list().

    //     for p in TaggedParts
    //     {
    //         // Pick up the module here
    //         local m to p:GetModule(__FARCtrlSrfModule).

    //         local pEventObject to list(p:UID, m).
    //         // m, list("ctrl dflct", CtrlTgt, CtrlCur) // list("Pitch %", PitTgt, PitCur), list("Yaw %", YawTgt, YawCur), list("Roll %", RollTgt, RollCur), 

    //         local TagNibs to p:Tag:Split("|").
            
    //         // Get the condition    
    //         local CtrlCond  to TagNibs[3].
    //         local CtrlCondParam to choose ParseStringScalar(CtrlCond:Split(":")[1], -1) if CtrlCond:Contains(":") else -1.
            
    //         if CtrlCond = "StgIgn"
    //         {
    //             local tgtStg to p:Stage + 1. // Assuming this stage lights just prior in stage ordering to decoupling this part
    //             local stgEngs to GetEnginesForStage(tgtStg).
    //             set eventParams to list(tgtStg, stgEngs).

    //             set checkDel to 
    //             { 
    //                 // 0: StageNumber of part
    //                 // 1: EngList
    //                 parameter _params is list().
                    
    //                 if Stage:Number = _params[0] + 1
    //                 {
    //                     local ignFlag to false.
    //                     for eng in _params[1]
    //                     {
    //                         if eng:Flameout or not eng:Ignition 
    //                         {
    //                             return false.
    //                         }
    //                         else
    //                         {
    //                             set ignFlag to true.
    //                         }
    //                     }
    //                     return ignFlag.
    //                 }
    //                 else
    //                 {
    //                     return false.
    //                 }
    //             }.
    //         }

    //         // Setup the action
    //         local ActionBites to TagNibs[2]:Split(";").
    //         for actBite in ActionBites
    //         {
    //             local CtrlNibbles to actBite:Split(",").
    //             for ctrlNib in CtrlNibbles
    //             {
    //                 local nibbles to ctrlNib:Split(":").
    //                 local ctrlKey to nibbles[0].
    //                 local ctrlVal to choose nibbles[1] if nibbles:Length > 1 else 0.

    //                 from { local i to 0. local doneflag to false. } until i >= __AeroModules[__FARCtrlSrfModule]:f:Keys:Length or doneFlag step { set i to i + 1.} do
    //                 {
    //                     // local key to __AeroModules[__FARCtrlSrfModule]:f:Keys[i].
    //                     local val to __AeroModules[__FARCtrlSrfModule]:f:Values[i].

    //                     if val:HasKey(ctrlKey)
    //                     {
    //                         // Initialize the field section
    //                         m:SetField(val:_, true).

    //                         // Confirm the field exists
    //                         if m:HasField(val:_)
    //                         {
    //                             if ctrlVal:HasSuffix("ToNumber")
    //                             {
    //                                 set ctrlVal to ParseStringScalar(nibbles[1], 0).
    //                             }
    //                             // If found, add the the object
    //                             pEventObject:Add(list(
    //                                 val[ctrlKey]
    //                                 ,ctrlVal
    //                                 ,m:GetField(val[ctrlKey])
    //                             )).
    //                         }
    //                         set doneFlag to true.
    //                     }
    //                 }
    //             }
    //         }

    //         if pEventObject:Length > 1
    //         {

    //         }










    //             for act in actions 
    //             {

    //             }
                    

    //                 if CtrlNibs:Length > 2
    //                 {

    //                 } 
    //                 else
    //                 {
    //                     set CtrlTgt to ParseStringScalar(CtrlNibs[1], CtrlTgt).
    //                 }
    //             }
                
    //             local CtrlItem to list().

    //             if p:HasModule(__FARCtrlSrfModule) 
    //             {
    //                 if CtrlTgt = 111
    //                 {
    //                     // #TODO: We don't have a valid target so no op for now? 
    //                 }
    //                 else
    //                 {
    //                     local m to p:GetModule(__FARCtrlSrfModule).
    //                     SetField(m, "std ctrl.", True).
    //                     set CtrlCur to m:GetField("ctrl dflct").
    //                         //set PitCur  to m:GetField("pitch %"),
    //                         //set YawCur  to m:GetField("yaw %"),
    //                         //set RollCur to m:GetField("roll %")

    //                     if CtrlTgt > -101 and CtrlTgt < 101 and CtrlTgt <> CtrlCur
    //                     {
    //                         set CtrlItem to lexicon(
    //                             p:UID, list(
    //                                 m, list("ctrl dflct", CtrlTgt, CtrlCur), // list("Pitch %", PitTgt, PitCur), list("Yaw %", YawTgt, YawCur), list("Roll %", RollTgt, RollCur), 
    //                                 list(   
    //                                 )
    //                             )
    //                         ).
    //                     }
    //                 }
    //             }
                
    //             if not ControlPartsObj:HasKey(CtrlCond) 
    //             {
    //                 ControlPartsObj:Add(
    //                     CtrlCond, lex(
    //                         CtrlCondParam, lex(
    //                             p:UID, list()
    //                         )
    //                     )
    //                 ).
    //             }
    //             else if not ControlParts[CtrlCond]:HasKey(CtrlCondParam)
    //             {
    //             }
    //         }
    //     }
    //     local resultFlag to False.





    //     local Current_MECO_ID to 999999.
        
    //     for m in AeroSurfaceModules 
    //     { 
    //         local ecoMET to p:Tag:Split("|")[2]:ToNumber(0).

    //         if ecoMET > 0 
    //         {
    //             if TaggedParts:HasKey(ecoMET)
    //             {
    //                 TaggedParts[ecoMET]:Add(p).
    //             }
    //             else
    //             {
    //                 TaggedParts:Add(ecoMET, list(p)).
    //             }

    //             set Current_MECO_ID to Min(Current_MECO_ID, ecoMET).
    //         }
    //     }
        
    //     local MECO_Time    to Current_MECO_ID.

    //     global MECO_Action_Counter to 0.

    //     if MECO_Time > 0 
    //     {
    //         local checkDel to 
    //         { 
    //             parameter _params is list(). 
                
    //             OutInfo("MECO T-{0}s ":Format(Round(MissionTime - _params[1], 2)), 1). 
    //             return MissionTime >= _params[1].
    //         }.

    //         local actionDel to 
    //         {
    //             parameter _params is list(). 
                
    //             set MECO_Action_Counter to MECO_Action_Counter + 1. 
                
    //             for eng in Ship:PartsTaggedPattern("Ascent\|MECO\|{0}":Format(_params[1]))
    //             {
    //                 if eng:Ignition and not eng:flameout
    //                 {
    //                     eng:shutdown.
    //                     if eng:HasGimbal 
    //                     {
    //                         DoAction(eng:Gimbal, "Lock Gimbal", true).
    //                     }
    //                     set eng:tag to "".
    //                 }
    //             }
    //             set g_ActiveEngines to GetActiveEngines(ship, "NoBooster").
    //             set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).
    //             set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                
    //             wait 0.01. 

    //             if Ship:PartsTaggedPattern("^Ascent\|MECO\|\d*(\.\d*)*"):Length > 0
    //             {
    //                 UnregisterLoopEvent("MECO").
    //                 return SetupMECOEventHandler().
    //             }
    //             else
    //             {
    //                 OutInfo("", 1).
    //                 set g_MECOArmed to False.
    //                 return g_MECOArmed.
    //             }
    //         }.
                
    //         local MECO_Event to CreateLoopEvent("MECO", "EngineCutoff", list(MECO_EngineID_List, Current_MECO_ID), checkDel@, actionDel@).
    //         if RegisterLoopEvent(MECO_Event)
    //         {
    //             set resultFlag to True.
    //             // OutDebug("MECO Handler Created").
    //         }
    //     }
    //     return resultFlag.
    // }
    

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
            set aeroModule to _aeroObject:GetModule(__FARCtrlSrfModule).
        }

        if aeroModule:IsType("PartModule")
        {
            aeroModule:SetField(__stdCtrlFieldName, True).
            
            set aeroModule:Part:Tag to "{0}[{1}]":Format(aeroModule:Part:Tag, aeroModule:GetField(__cdFieldName)).
            aeroModule:SetField(__cdFieldName, 0).
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

        for m in _ves:ModulesNamed(__FARCtrlSrfModule)
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
            set aeroModule to _aeroObject:GetModule(__FARCtrlSrfModule).
        }
        
        if aeroModule:IsType("PartModule")
        {
            aeroModule:SetField(__stdCtrlFieldName, True).
            local fldName to __cdFieldName.

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

        for m in _ves:ModulesNamed(__FARCtrlSrfModule)
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
            set aeroModule to aeroPart:GetModule(__FARCtrlSrfModule).
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