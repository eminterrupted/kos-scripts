@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/nav").

// *~ Variables ~* //
// #region

// -- Globals
// #region
// global avlThr to 0.
// global avlThrPres to 0.
// global curThr to 0.
// global maxThr to 0.
// global maxThrPres to 0.
// global posThr to 0.
// global posThrPres to 0.
// #endregion

// -- Local
// #region
// #endregion

// -- Anonymous -- //
//        
// #region

// -- GetEngineThrustData() helpers
// These are anonymous functions used with the GetEngineThrustData() function, 
// defined here so as to not require redefinition on each call
    // // 1111: current, max, available, possible
    // global thrDel_all to {   
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    //     set maxThr      to maxThr   + eng:MaxThrust.
    //     set avlThr      to avlThr   + eng:AvailableThrust.
    //     set posThr      to posThr   + eng:PossibleThrust.
    // }.

    // // 1000: current
    // global thrDel_cur to {   
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    // }.

    // // 1100: current, max
    // global thrDel_cur_max to {   
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    //     set maxThr      to maxThr   + eng:MaxThrust.     
    // }.

    // // 1110: current, max, available
    // global thrDel_cur_max_avl to {   
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    //     set maxThr      to maxThr   + eng:MaxThrust.
    //     set avlThr      to avlThr   + eng:AvailableThrust.    
    // }.

    // // 1010: current, available
    // global thrDel_cur_avl to {   
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    //     set avlThr      to avlThr   + eng:AvailableThrust.
    // }.

    // // 1011: current, available, possible
    // global thrDel_cur_avl_pos to {   
    //     parameter eng.

    //     set curThr     to curThr   + eng:Thrust.
    //     set avlThr     to avlThr   + eng:AvailableThrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 1011: current, available, possible
    // global thrDel_cur_max_pos to {   
    //     parameter eng.

    //     set curThr     to curThr   + eng:Thrust.
    //     set maxThr     to maxThr   + eng:MaximumThrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 1001: current, possible
    // global thrDel_cur_pos to {
    //     parameter eng.

    //     set curThr      to curThr   + eng:Thrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 0100: max
    // global thrDel_max to {
    //     parameter eng.

    //     set maxThr      to maxThr   + eng:MaxThrust.
    // }.

    // // 0100: max with pressure
    // global thrDel_maxpres to {
    //     parameter eng,
    //               atmPres is 0.

    //     set maxThrPres to maxThrPres + eng:MaxThrustAt(atmPres).
    // }.

    // // 0110: max, available
    // global thrDel_max_avl to {
    //     parameter eng.

    //     set maxThr      to maxThr   + eng:MaxThrust.
    //     set avlThr      to avlThr   + eng:AvailableThrust.
    // }.

    // // 0111: max, available, possible
    // global thrDel_max_avl_pos to {
    //     parameter eng.

    //     set maxThr      to maxThr   + eng:MaxThrust.
    //     set avlThr      to avlThr   + eng:AvailableThrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 0101: max, possible
    // global thrDel_max_pos to {
    //     parameter eng.

    //     set maxThr      to maxThr   + eng:MaxThrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 0010: available
    // global thrDel_avl to {
    //     parameter eng.

    //     set avlThr      to avlThr   + eng:AvailableThrust.    
    // }.

    // // 0010: available with pressure
    // global thrDel_avlpres to {
    //     parameter eng,
    //               atmPres is 0.

    //     set avlThrPres to avlThrPres + eng:AvailableThrustAt(atmPres).
    // }.

    // // 0011: available, possible
    // global thrDel_avl_pos to {
    //     parameter eng.

    //     set avlThr      to avlThr   + eng:AvailableThrust.
    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 0001: possible
    // global thrDel_pos to {
    //     parameter eng.

    //     set posThr     to posThr  + eng:PossibleThrust.
    // }.

    // // 0001: possible with pressure
    // global thrDel_pospres to {
    //     parameter eng,
    //               atmPres is 0.

    //     set posThrPres to posThrPres + eng:PossibleThrustAt(atmPres).
    // }.

    // // A grouped function for all pressure-dependent readings
    // global thrDel_allpres to {
    //     parameter eng,
    //               atmPres.

    //     thrDel_all:call(eng).
    //     set maxThrPres to thrDel_maxpres:call(eng, atmPres).
    //     set avlThrPres to thrDel_avlpres:call(eng, atmPres).
    //     set posThrPres to thrDel_pospres:call(eng, atmPres).
    // }.
// #endregion

// -- Local Lists / Lexicons
// #region
local resList to list(
    "LiquidFuel",
    "Oxidizer"
).

local sepList to list(
    "sepMotor1", 
    "sepMotorJr",
    "B9_Engine_T2_SRBS",
    "B9_Engine_T2A_SRBS",
    "B9_Engine_T2_SRBS_Jr",
    "B9_Engine_T2A_SRBS_Jr",
    "B9.Engine.T2.SRBS",
    "B9.Engine.T2A.SRBS",
    "B9.Engine.T2.SRBS.Jr",
    "B9.Engine.T2A.SRBS.Jr",
    "nesdIntRcsSep",
    "creiNesdIntRcsSepJr",
    "creiNesdIntRcsSepMini"
).
// #endregion

// local thrDelLex to lex(
//     "all", thrDel_all@
//     ,"allPres", thrDel_allpres@
//     ,"cur", thrDel_cur@
//     ,"avl", thrDel_avl@
//     ,"max", thrDel_max@
//     ,"pos", thrDel_pos@
//     ,"avlPres", thrDel_avlPres@
//     ,"maxPres", thrDel_maxpres@
//     ,"posPres", thrDel_pospres@
// ).
// #endregion


// *~ Functions ~* //
// #region

// -- Steering
// #region
// GetSteeringDir :: <string> -> <direction>
// Returns the current vessel direction to align with the provided orientation string
global function GetSteeringDir
{
    parameter orientation.

    local tgtDir to { if hasTarget { return target:position.} else { return ship:facing.}}.
    
    local dirLookup to lex(
        "pro",          Ship:Prograde:Vector
        ,"prograde",    Ship:Prograde:Vector
        ,"sun",         Sun:Position
        ,"-sun",        -Sun:Position
        ,"sunOut",      -Sun:Position
        ,"retro",       Ship:Retrograde:Vector
        ,"retrograde",  Ship:Retrograde:Vector
        ,"facing",      Ship:Facing:Vector
        ,"body",        Body:Position
        ,"bodyOut",     -Body:Position
        ,"radOut",      -Body:Position
        ,"home",        Body("Kerbin"):Position
        ,"srfRetro",    Ship:SrfRetrograde:Vector
        ,"up",          vcrs(ship:body:position - ship:position, ship:velocity:orbit):normalized
        ,"north",       north:vector
        ,"tgt",         tgtDir:call()
        ,"target",      tgtDir:call()
    ).
    return lookDirUp(dirLookup[orientation:split("-")[0]], dirLookup[orientation:split("-")[1]]).

    // if orientation = "pro-sun"
    // {
    //     return lookDirUp(Ship:Prograde:Vector, Sun:Position).
    // }
    // else if orientation = "retro-sun"
    // {
    //     return lookDirUp(Ship:Retrograde:Vector, Sun:Position).
    // }
    // else if orientation = "facing-sun"
    // {
    //     return lookDirUp(Ship:facing:vector, Sun:Position).
    // }
    // else if orientation = "pro-body"
    // {
    //     return lookDirUp(Ship:Prograde:Vector, Body:Position).
    // }
    // else if orientation = "pro-radOut"
    // {
    //     return lookDirUp(Ship:Prograde:Vector, -Body:Position).
    // }
    // else if orientation = "body-pro"
    // {
    //     return lookDirUp(Body:Position, Ship:Prograde:Vector).
    // }
    // else if orientation = "body-sun"
    // {
    //     return lookDirUp(Body:Position, Sun:Position).
    // }
    // else if orientation = "sun-pro" 
    // {
    //     return lookDirUp(Sun:Position, Ship:Prograde:Vector).
    // }
    // else if orientation = "target-sun"
    // {
    //     return lookDirUp(target:Position, Sun:Position).
    // }
    // else if orientation = "home-sun"
    // {
    //     return lookDirUp(Body("Kerbin"):Position, Sun:Position).
    // }
    // else if orientation = "radOut-sun"
    // {
    //     return lookDirUp(-Body:Position, Sun:Position).
    // }
    // else if orientation = "srfRetro-sun"
    // {
    //     return lookDirUp(Ship:SrfRetrograde:Vector, Sun:Position).
    // }
    // else
    // {
    //     return Ship:facing.
    // }
}

global function SrfRetroSafe 
{
    parameter radarAlt is Ship:Altitude - Ship:GeoPosition:TerrainHeight.
    
    if radarAlt > 100
    {
        return list(GetSteeringDir("srfRetro-radOut"), "srfRetro_Locked1").
    }
    else if Ship:VerticalSpeed < 0 
    {
        return list(GetSteeringDir("srfRetro-radOut"), "srfRetro_Locked2").
    }
    else
    {
        return list(GetSteeringDir("radOut-pro"), "upPos_Override").
    }
}

// TranslateToVec :: (Desired position<vector>) -> (CurrentError<scalar>)
// Given a vector, will try to use translation to move the vessel into position
global function TranslateToVec
{
    parameter tgtVec.

    set ship:control:translation to tgtVec.
    return round(tgtVec:mag, 5).
}

// Approach a docking port
global function TranslateToDockingPort
{
    parameter tgtPort,
              ctrlPort,
              dist,
              spd.

    ctrlPort:controlFrom().

    lock distOffset to tgtPort:portFacing:vector * dist.
    lock approachVec to tgtPort:nodePosition - ctrlPort:nodePosition + distOffset.
    lock relVel to ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to -tgtPort:facing:vector.

    OutMsg("Translating to TgtPort (" + tgtPort:name + "|" + tgtPort:UID + ")").
    OutInfo("Target Distance: " + dist).
    until ctrlPort:state <> "ready" 
    {
        TranslateToVec((approachVec:normalized * spd) - relVel).
        local distVec to (tgtPort:nodePosition - ctrlPort:nodePosition).
        if vang(ctrlPort:portFacing:vector, distVec) < 2 and abs(dist - distVec:mag) < 0.1 
        {
            break.
        }
        wait 0.01.
        OutInfo2("Current distance: " + round(target:position:mag, 1)).
    }
}

global function ToggleControlSurfaces
{
    parameter _ves is ship,
              _action is "deploy".

    for m in _ves:modulesNamed("ModuleControlSurface")
    {
        if _action = "deploy"
        {
            if m:part:tag:length = 0
            {
                DoAction(m, "Activate Pitch Control").
                DoAction(m, "Activate Yaw Control").
                DoAction(m, "Activate Roll Control").
            }
            else
            {
                if m:part:tag[0] = "1"
                {
                    DoAction(m, "Activate Pitch Control").
                }
                if m:part:tag[1] = "1"
                {
                    DoAction(m, "Activate Yaw Control").
                }
                if m:part:tag[2] = "1"
                {
                    DoAction(m, "Activate Roll Control").
                }
            }
        }
        else if _action = "stow"
        {
            local tagStr to 0.
            if m:getField("pitch") 
            {
                set tagStr to tagStr + 100.
                DoAction(m, "deactivate pitch control").
            }
            if m:getField("yaw") 
            {
                set tagStr to tagStr + 10.
                DoAction(m, "deactivate yaw control").
            }
            if m:getField("roll") 
            {
                set tagStr to tagStr + 1.
                DoAction(m, "deactivate roll control").
            }

            if tagStr:toString:length = 1
            {
                set tagStr to "00" + tagStr:toString.
            }
            else if tagStr:toString:length = 2
            {
                set tagStr to "0" + tagStr:toString.
            }
            set m:part:tag to tagStr.
        }
    }
}


// global function GetRollDegrees
// {
//     local rollAng to Ship:facing:roll - Ship:prograde:roll.
// }
// #endregion

// -- Resources
// #region

// GetECDraw :: (<string>) -> <bool>
// Returns the amount of EC that is used over time
global function GetECDraw
{
    parameter checkType is "sample".

    local charge to 0.
    local draw   to 0.

    if checkType = "sample" 
    {
        set charge to Ship:Resources:EC.
        wait 1.
        set draw to charge - Ship:Resources:EC.
    }

    print draw.

    return false.
}

// ParseResource :: (<any>, <parts<list>|ship|element>) -> <resource>
// Returns the resource object on the provided ship or element by name or direct resource
// Can convert string into resource as well as accept an actual resource
global function ParseResourceParam
{
    parameter resParam,
              resElement is ship.

    local _itemSelections to lex().
    local srcElement to "".
    if resElement = "" or resElement:IsType("Vessel")
    {
        local _items to ship:elements.
        local itemSelectDel to {
            parameter _i.
            
            set _itemSelections[Stk(_i, "=v")] to _i.
            set errLvl to _items:remove(_items:indexOf(_i)).
            if errLvl = 1 OutLog("Failed to move _item: {0}":format(_i)).
            else OutLog("Successfully moved item: {0}":format(_i)).
        }.
        return PromptItemMultiSelect(ship:elements, "Pick Resource Source Object", itemSelectDel@, -1, true, "srcElement").
    }

    if resParam:isType("Resource") return resParam.
    else if resParam:isType("String") 
    {
        for res in srcElement:resources
        {
            if resParam = res:name 
            {

            }
        }
        
        OutTee("No resource named {0} in source element: {1}":format(resParam, srcElement:name), 0, 2).
        return "".
    }
}
// #endregion

// -- Mass
// #region

// StageMass :: (<scalar>) -> <lexicon>
// Returns a lex containing mass statistics for a given stage number
global function StageMass
{
    parameter stg.

    local stgMass to 0.

    //ISSUE: stgFuelMass appears to be about half (or at least, lower than) 
    //what it should be
    local stgFuelMass to 0.
    local stgShipMass to 0.
    
    local stgEngs to GetEnginesByStage(stg).
    local engResUsed to list().
    for eng in stgEngs
    {
        for k in eng:ConsumedResources:Keys 
        {
            if not engResUsed:Contains(k) engResUsed:Add(k:replace(" ", "")).
        }
    }

    for p in Ship:parts
    {
        if p:typeName = "Decoupler" 
        {
            if p:Stage <= stg set stgShipMass to stgShipMass + p:Mass.
            if p:Stage = stg set stgMass to stgMass + p:Mass.
        }
        else if p:DecoupledIn <= stg
        {
            set stgShipMass to stgShipMass + p:Mass.
            if p:DecoupledIn = stg 
            {
                set stgMass to stgMass + p:Mass.
            }
        }

        if p:DecoupledIn = stg - 1 and p:Resources:Length > 0 
        {
            for res in p:Resources
            {
                if engResUsed:Contains(res:Name) 
                {
                    // print "Calculating: " + res:Name.
                    set stgFuelMass to stgFuelMass + (res:amount * res:density).
                }
            }
        }
    }

    return lex("stage", stgMass, "fuel", stgFuelMass, "ship", stgShipMass).
}
// #endregion

// -- Engines
// #region

// Methods
global function ArmEngCutoff
{
    when ship:availablethrust <= 0.1 and stage:number <= g_stopStage then
    {
        set Ship:Control:PilotMainThrottle to 0.
        lock throttle to 0.
        set g_engBurnout to true.
    }
}

// GetEngines :: ([<string>]) -> <list>Engines
// Returns engines by state (any, active)
global function GetEngines
{
    parameter engState is "any", includeSep is true.

    local engList to list().
    local engs to buildList("engines").
    
    if engState = "active"  
    {
        for eng in engs
        {
            if includeSep
            {
                if eng:Ignition and not eng:FlameOut engList:Add(eng).
            }
            else if not sepList:Contains(eng) or eng:Tag = ""
            {
                if eng:Ignition and not eng:FlameOut engList:Add(eng).
            }
        }
    }
    else if engState = "off"
    {
        for eng in engs
        {
            if includeSep
            {
                if not eng:Ignition engList:Add(eng).
            }
            else if not sepList:Contains(eng) or eng:Tag = ""
            {
                if not eng:Ignition engList:Add(eng).
            }
        }
    }
    else 
    {
        if not includeSep
        {
            for eng in engs
            {
                if not sepList:Contains(eng) or eng:Tag = ""
                {
                    engList:Add(eng).
                }
            }
        }
        else return engs.
    }

    return engList.
}

// GetEnginesLex :: ([<string>]) -> <Lex>Engines
// Returns engines given state, grouped by any parameter
global function GetEnginesLex
{
    parameter engState is "any", 
              groupBy is "stg",
              includeSep is true.

    local engLex to lex().
    local engList to list().
    
    local engHit to false.

    local checkActive to { parameter _eng. return (_eng:ignition and not _eng:flameout).}.
    local checkOff to { parameter _eng. return not _eng:ignition.}.
    local checkSep to { parameter _eng. return sepList:contains(_eng).}.

    if groupBy = "stg"
    {
        set engLex to lex(
            "engaged", lex()
            ,"decoupledIn", lex()
            ,"combi", lex()
        ).
    }
    else if groupBy = "sep"
    {
        set engLex to lex(
            "sepMotors", list()
            ,"mainEngines", list()
        ).
    }

    for eng in ship:engines
    {
        set engHit to false.
        if includeSep or (not sepList:contains(eng:name) or eng:tag <> "")
        {
            if engState = "active"
            {
                if checkActive:call(eng) 
                {
                    engList:add(eng).
                    set engHit to true.
                }
            }
            else if engState = "off"
            {
                if checkOff:call(eng) 
                {
                    engList:add(eng).
                    set engHit to true.
                }
            }
            else if engState = "sep"
            {
                if checkSep:call(eng) 
                {
                    engList:add(eng).
                    set engHit to true.
                }
            }
            else if engState = "any"
            {
                engList:add(eng).
                set engHit to true.
            }
        }

        if engHit
        {
            if groupBy = "stg"
            {
                local engCombiTag to "{0}|{1}":format(eng:stage, eng:decoupledIn).

                if engLex["engaged"]:hasKey(eng:stage) 
                {
                    engLex["engaged"][eng:stage]:add(eng).
                }
                else
                {
                    set engLex["engaged"][eng:stage] to list(eng).
                }
                
                if engLex["decoupledIn"]:hasKey(eng:decoupledIn) 
                {
                    engLex["decoupledIn"][eng:decoupledIn]:add(eng).
                }
                else
                {
                    set engLex["decoupledIn"][eng:decoupledIn] to list(eng).
                }

                if engLex["combi"]:hasKey(engCombiTag) 
                {
                    engLex["combi"][engCombiTag]:add(eng).
                }
                else
                {
                        set engLex["combi"][engCombiTag] to list(eng).
                }
            }
            else if groupBy = "type"
            {
                if engLex:hasKey(eng:name)
                {
                    engLex[eng:name]:add(eng).
                }
                else
                {
                    set engLex[eng:name] to list(eng).
                }
            }
            else if groupBy = "sep"
            {
                if not engLex:hasKey("sep")
                {
                    set engLex to lex("sep", list(), "main", list()).
                }

                if sepList:contains(eng:name)
                {
                    engLex["sep"]:add(eng).
                }
                else
                {
                    engLex["main"]:add(eng).
                }
            }
            else if groupBy = "flat"
            {
                if not engLex:hasKey("engs")
                {
                    set engLex["engs"] to list(eng).
                }
                else
                {
                    engLex["engs"]:add(eng).
                }
            }
        }
    }
    
    return engLex.
}

// GetEnginesByStage :: (<int>, [bool]) -> <list>Engines
// Returns engines for a given stage number
global function GetEnginesByStage
{
    parameter stg,
              includeSep is false.

    local engList to buildList("engines").
    local stgEngs to list().

    for eng in engList
    {
        if eng:Stage = stg
        {
            if not includeSep
            {
                if not sepList:Contains(eng:Name) stgEngs:Add(eng).
            }
            else
            {
                stgEngs:Add(eng).
            }
        }
    }
    return stgEngs.
}

// GetEnginePerfData :: (<list>Engines, [<string>]Functionality Bitmask) -> Lexicon()
// Returns performance data according to input bitmask. 
global function GetEnginesPerfData 
{
    parameter _engList to GetEngines("active"),
              _funcMask to "1010:10",
              altPres to ship:body:atm:altitudePressure(ship:altitude),
              includeSep to false.
    
    local retThr        to false.
    local retThrCur     to false.
    local retThrMax     to false.
    local retThrAvl     to false.
    local retThrPos     to false.
    local retThrPres    to false.

    local retFlow       to false.
    local retFlowFuel   to false.
    local retFlowMass   to false.

    local avlThr        to 0.
    local avlThrPres    to 0.
    local curThr        to 0.
    local maxThr        to 0.
    local maxThrPres    to 0.
    local posThr        to 0.
    local posThrPres    to 0.
    local fuelFlow      to 0.
    local fuelFlowMax   to 0.
    local massFlow      to 0.
    local massFlowMax   to 0.

    local retObj to lex().
    local thrObj to lex().
    local flowObj to lex().

    set _funcMask to _funcMask:split(":").
    // Thrust loop
    if _funcMask[0]:toNumber(0) > 0 
    {
        set retThr to true.
        if _funcMask[0][0] = "1" set retThrCur to true.
        if _funcMask[0][1] = "1" set retThrMax to true.
        if _funcMask[0][2] = "1" set retThrAvl to true.
        if _funcMask[0][3] = "1" set retThrPos to true.
        if altPres > 0         set retThrPres to true.
    }

    if _funcMask:length > 1 {
        if _funcMask[1]:toNumber(0) > 0 
        {
            set retFlow to true.
            if _funcMask[1][0] = "1" set retFlowFuel to true.
            if _funcMask[1][1] = "1" set retFlowMass to true.
        }
    }

    for thisEng in _engList
    {
        if includeSep or (not includeSep and not sepList:Contains(thisEng:name))
        {
            // Thrust data
            if retThr
            {
                // Thrust
                // Current
                if retThrCur set curThr to curThr + thisEng:thrust.
                // Max
                if retThrMax set maxThr to maxThr + thisEng:maxThrust.
                // Available
                if retThrAvl set avlThr to avlThr + thisEng:availableThrust.
                // Possible
                if retThrPos set posThr to posThr + thisEng:possibleThrust.
                // Atmospheric
                if retThrPres
                {
                    if retThrAvl set avlThrPres to avlThrPres + thisEng:availableThrustAt(altPres).
                    if retThrMax set maxThrPres to maxThrPres + thisEng:maxThrustAt(altPres).
                    if retThrPos set posThrPres to posThrPres + thisEng:possibleThrustAt(altPres).
                }
            }

            // Fuel Flow Data
            if retFlow
            {
                if retFlowFuel
                {
                    set fuelFlow to fuelFlow + thisEng:fuelFlow.
                    set fuelFlowMax to fuelFlowMax + thisEng:maxFuelFlow.
                }
                if retFlowMass
                {
                    set massFlow to massFlow + thisEng:massFlow.
                    set massFlowMax to massFlowMax + thisEng:maxMassFlow.
                }
            }
        }
    }

    if retThr
    {
        set retObj["thr"] to thrObj.
        if not retThrPres 
        {
            set maxThrPres to maxThr.
            set avlThrPres to avlThr.
            set posThrPres to posThr.
        }
        if retThrCur set thrObj["cur"] to curThr.
        if retThrMax 
        {
            set thrObj["max"] to maxThr.
            set thrObj["maxPres"] to maxThrPres.
        }
        if retThrAvl 
        {
            set thrObj["avl"] to avlThr.
            set thrObj["avlPres"] to avlThrPres.
        }
        if retThrPos 
        {
            set thrObj["pos"] to posThr.
            set thrObj["posPres"] to posThrPres.
        }
    }
    if retFlow
    {
        if retFlowFuel 
        {
            set flowObj["fuel"] to fuelFlow.
            set flowObj["fuelMax"] to fuelFlowMax.
        }
        if retFlowMass 
        {
            set flowObj["mass"] to massFlow.
            set flowObj["massMax"] to massFlowMax.
        }
        set retObj["flow"] to flowObj.
    }

    return retObj.
}

// If EngineIgnitor is installed, return ignition info for engine
global function GetEngineIgnitionInfo
{
    parameter eng,
              bitMask is "1111".

    //if bitMask:isType("Scalar") set bitMask to bitMask:toString().
    local engLex to lex().
    if eng:hasModule("ModuleEngineIgnitor")
    {
        local m to eng:getModule("ModuleEngineIgnitor").
        if bitMask[0] = "1"
        {
            local ig to m:getField("ignitions"):replace(" ]",""):split("[ ")[1].
            set engLex["ignitions"] to ig.
            set engLex["igRemaining"] to ig:split("/")[0]:toNumber(0).
        }
        if bitMask[1] = "1"
        {
            set engLex["fuelStability"] to m:getField("fuel flow").
        }
        if bitMask[2] = "1"
        {
            set engLex["engStatus"] to m:getField("engine state").
        }
        if bitMask[3] = "1"
        {
            local autoIg to m:getField("auto-ignite").
            set engLex["autoIgnite"] to autoIg.
            set engLex["engTemp"] to autoIg:split("/")[0].
            set engLex["autoIgniteThresh"] to autoIg:split("/")[1].
        }
    }
    return engLex.
}

// GetStageThrust :: (<list>Engines, [<string>]) -> <scalar>
// Returns summed thrust of a given type for a given stage
global function GetStageThrust
{
    parameter stg,
              thrType is "cur",
              includeSep is false.

    local stgThr to 0.
    local engList to buildList("engines").

    for eng in engList
    {
        if eng:Stage = stg
        {
            if not includeSep
            {
                if not sepList:Contains(eng:Name)
                {
                    if thrType = "cur"         set stgThr to stgThr + eng:Thrust.
                    else if thrType = "max"     set stgThr to stgThr + eng:MaxThrust.
                    else if thrType = "avail"   set stgThr to stgThr + eng:AvailableThrust.
                    else if thrType = "poss"    set stgThr to stgThr + eng:PossibleThrust.
                }
            }
            else
            {
                if thrType = "cur"         set stgThr to stgThr + eng:Thrust.
                else if thrType = "max"     set stgThr to stgThr + eng:MaxThrust.
                else if thrType = "avail"   set stgThr to stgThr + eng:AvailableThrust.
                else if thrType = "poss"    set stgThr to stgThr + eng:PossibleThrust.
            }
        }
    }
    return stgThr.
}


// GetStageThrustData :: (<list>Engines, [<bool>IncludeSeperationMotors], [<double>AltPressure]) -> <lex>
// Returns a lexicon of thrust values based on the passed-in bitmask for values to include
// "1111" : Current, Max, Available, Possible
// If provided an altitudePressure value higher than 0, will also get those values, otherwise these will be set to non-pressure versions
global function GetStageEnginePerfData
{
    parameter stg is stage:number,
              valMaskStr is "1111:1111:11",
              includeSep is false,
              altPres is 0.

    local retThr        to false.
    local retThrCur     to false.
    local retThrMax     to false.
    local retThrAvl     to false.
    local retThrPos     to false.
    local retThrPres    to false.

    local retFlow       to false.
    local retFlowFuel   to false.
    local retFlowMass   to false.
    local retFlowEng    to false.
    local retFlowRes    to false.

    local retRes        to false.
    local retResSum     to false.
    local retResEng     to false.

    local thrObj     to lex().
    local flowObj    to lex().
    local resObj    to lex().

    local retObj        to lex().

    local valMask to choose valMaskStr:split(":") if valMaskStr:isType("string") else valMaskStr:toString:split(":").    
    local engList to GetEnginesByStage(stg).

    // Choose the delegate. Lots of code here, but it means we only check this once per call vs. once with every engine
    // local thrDel to choose thrDel_all@   if valMask = "1111" else 
    //     choose thrDel_cur@               if valMask = "1000" else 
    //     choose thrDel_cur_avl@           if valMask = "1010" else
    //     choose thrDel_cur_max@           if valMask = "1100" else 
    //     choose thrDel_cur_pos@           if valMask = "1001" else
    //     choose thrDel_cur_max_avl@       if valMask = "1110" else 
    //     choose thrDel_cur_max_pos@       if valMask = "1101" else
    //     choose thrDel_cur_avl_pos@       if valMask = "1011" else 
    //     choose thrDel_avl@               if valMask = "0010" else 
    //     choose thrDel_avl_pos@           if valMask = "0011" else 
    //     choose thrDel_max@               if valMask = "0100" else 
    //     choose thrDel_max_avl@           if valMask = "0110" else 
    //     choose thrDel_max_avl_pos@       if valMask = "0111" else 
    //     choose thrDel_max_pos@           if valMask = "0101" else 
    //     thrDel_pos@.

    // Thrust loop
    if valMask[0]:toNumber(0) > 0 // Thrust values
    {
        set retThr to true.
        if valMask[0][0] = "1" set retThrCur to true.
        if valMask[0][1] = "1" set retThrMax to true.
        if valMask[0][2] = "1" set retThrAvl to true.
        if valMask[0][3] = "1" set retThrPos to true.
        if altPres > 0         set retThrPres to true.
    }

    if valMask:length > 1  // Fuel flow rates
    {
        if valMask[1]:toNumber(0) > 0 
        {
            set retFlow to true.
            if valMask[1][0] = "1" set retFlowFuel to true.
            if valMask[1][1] = "1" set retFlowMass to true.
            if valMask[1][2] = "1" set retFlowEng to true.
            if valMask[1][3] = "1" set retFlowRes to true.
        }
        
        if valMask:length > 2  // Resource objects
        {
            if valMask[2]:toNumber(0) > 0 
            {
                set retRes to true.
                if valMask[2][0] = "1" set retResSum to true.
                if valMask[2][1] = "1" set retResEng to true.
            }
        }
    }

    local avlThrPres    to 0.
    local avlThr        to 0.
    local curThr        to 0.
    local maxThr        to 0.
    local maxThrPres    to 0.
    local posThr        to 0.
    local posThrPres    to 0.
    local fuelFlow      to 0.
    local fuelFlowMax   to 0.
    local massFlow      to 0.
    local massFlowMax   to 0.

    
    for thisEng in engList
    {        
        if includeSep or (not includeSep and not sepList:Contains(thisEng:name))
        {
            // Thrust data
            if retThr
            {
                // Thrust
                // Current
                if retThrCur set curThr to curThr + thisEng:thrust.
                // Max
                if retThrMax set maxThr to maxThr + thisEng:maxThrust.
                // Available
                if retThrAvl set avlThr to avlThr + thisEng:availableThrust.
                // Possible
                if retThrPos set posThr to posThr + thisEng:possibleThrust.
                // Atmospheric
                if retThrPres
                {
                    if retThrAvl set avlThrPres to avlThrPres + thisEng:availableThrustAt(altPres).
                    if retThrMax set maxThrPres to maxThrPres + thisEng:maxThrustAt(altPres).
                    if retThrPos set posThrPres to posThrPres + thisEng:possibleThrustAt(altPres).
                }
            }

            // Fuel Flow Data
            if retFlow
            {
                if retFlowFuel
                {
                    set fuelFlow to fuelFlow + thisEng:fuelFlow.
                    set fuelFlowMax to fuelFlowMax + thisEng:maxFuelFlow.
                }
                if retFlowMass
                {
                    set massFlow to massFlow + thisEng:massFlow.
                    set massFlowMax to massFlowMax + thisEng:maxMassFlow.
                }
                if retFlowEng
                {
                    if flowObj:hasKey("eng")
                    {
                        if not flowObj:hasKey(stg)
                        {
                            set flowObj[stg] to lex().
                        }
                    }
                    else
                    {
                        set flowObj[stg] to lex().
                    }
                    set flowObj[stg][thisEng:cid] to lex(
                        "FuelFlow", thisEng:fuelFlow
                        ,"MaxFuelFlow", thisEng:maxFuelFlow
                        ,"MassFlow", thisEng:massFlow
                        ,"MaxMassFlow", thisEng:maxMassFlow
                    ).
                }
                if retFlowRes
                {
                    if not flowObj:hasKey(stg) set flowObj[stg] to lex(thisEng:cid, lex()).
                    set flowObj[stg][thisEng:cid]["RESOBJ"] to thisEng:consumedResources.
                }
            }

        // Resource Data
            if retRes
            {
                for res in thisEng:consumedResources:values
                {
                    local resLex to lex().

                    if retResSum
                    {
                        set resLex to choose resObj[res:name] if resObj:hasKey(res:name) else lex(
                            "FuelFlow", 0
                            ,"MaxFuelFlow", 0
                            ,"MassFlow", 0
                            ,"MaxMassFlow", 0
                            ,"Density", res:density
                            ,"Ratio", res:ratio
                            ,"Amount", res:amount
                            ,"Capacity", res:capacity
                        ).

                        set resLex["FuelFlow"]       to resLex["FuelFlow"]    + res:fuelFlow.
                        set resLex["MaxFuelFlow"]    to resLex["MaxFuelFlow"] + res:maxFuelFlow.
                        set resLex["MassFlow"]       to resLex["MassFlow"]    + res:massFlow.
                        set resLex["MaxMassFlow"]    to resLex["MaxMassFlow"] + res:maxMassFlow.
                    }

                    if retResEng
                    {
                        if not resObj:hasKey("EngData") set resObj["EngData"] to lex().

                        set resObj["EngData"][thisEng:cid] to lex(
                            "FuelFlow", res:fuelFlow
                            ,"MaxFuelFlow", res:maxFuelFlow
                            ,"MassFlow", res:massFlow
                            ,"MaxMassFlow", res:maxMassFlow
                        ).
                    }

                    set resObj[res:name] to resLex.
                }
            }
        }
    }

    if retThr 
    {
        if retThrCur set thrObj["cur"] to curThr.
        if retThrMax set thrObj["max"] to maxThr.
        if retThrAvl set thrObj["avl"] to avlThr.
        if retThrPos set thrObj["pos"] to posThr.
        if retThrPres 
        {
            set thrObj["maxPres"] to maxThrPres.
            set thrObj["avlPres"] to avlThrPres.
            set thrObj["posPres"] to posThrPres.
        }
        set retObj["thr"] to thrObj.
    }
    if retFlow
    {
        if retFlowFuel 
        {
            set flowObj["fuel"] to fuelFlow.
            set flowObj["fuelMax"] to fuelFlowMax.
        }
        if retFlowMass 
        {
            set flowObj["mass"] to massFlow.
            set flowObj["massMax"] to massFlowMax.
        }
        set retObj["flow"] to flowObj.
    }
    if retRes
    {
        set retObj["res"] to resObj.
    }
    
    return retObj.
}


// GetTotalThrust :: (<list>Engines, [<string>]) -> <scalar>
// Returns summed thrust of a given type for a list of engines
global function GetTotalThrust
{
    parameter engList,
              thrType is "curr".

    local totThr to 0.

    if engList:Length > 0
    {
        if thrType = "curr"
        {
            for eng in engList set totThr to totThr + eng:Thrust.
        }
        else if thrType = "max" 
        {
            for eng in engList set totThr to totThr + eng:MaxThrust.
        }
        else if thrType = "avail" 
        {
            for eng in engList set totThr to totThr + eng:AvailableThrust.
        }
        else if thrType = "poss"
        {
            for eng in engList set totThr to totThr + eng:PossibleThrust.
        }
        return totThr.
    }
    else
    {
        return 0.
    }
}

// GetTWRForCurrentStage :: <scalar> -> <scalar>
// Returns the TWR for a given stage
// TODO: Implent TWR Projection for future stages (currently only active stage)
global function GetTWRForStage
{
    parameter stg is Stage:Number.

    local stgThr to GetStageThrust(stg, "poss", true).
    local stgMass to StageMass(stg)["ship"].

    return stgThr / (stgMass * Ship:Body:Mu).
}

// GetTotalISP :: (<list>Engines) -> <scalar>
// Returns averaged ISP for a list of engines
global function GetTotalIsp
{
    parameter engList, 
              mode is "vac".

    local relThr to 0.
    local totThr to 0.

    local engIsp to { 
        parameter eng. 
        if mode = "vac" return eng:VISP.
        if mode = "sl" return eng:SLISP.
        if mode = "cur" return eng:ispAt(body:ATM:AltitudePressure(Ship:Altitude)).
    }.

    if engList:Length > 0 
    {
        for eng in engList
        {
            set totThr to totThr + eng:PossibleThrust.
            set relThr to relThr + (eng:PossibleThrust / engIsp(eng)).
        }

        // clrDisp(30).
        // print "GetTotalIsp                    " at (2, 30).
        // print "stg: " + stg.
        // print "totThr: " + totThr at (2, 31).
        // print "relThr: " + relThr at (2, 32).
        //Breakpoint().
        if totThr = 0
        {
            return 0.00001.
        }
        else
        {
            return totThr / relThr.
        }
    }
    else
    {
        return 0.00001.
    }
}

// GetExhVel :: (<list>Engines) -> <scalar>
// Returns the averaged exhaust velocity for a list of engines
global function GetExhVel
{
    parameter engList, mode is "vac".

    return Constant:g0 * GetTotalIsp(engList, mode).
}
// #endregion

// -- Local gravity
// #region

// GetLocalGravityOnVessel -- ([<ship>], [<body>]) -> <scalar>
// Returns the local force of gravity on a vessel given ship and body
global function GetLocalGravityOnVessel
{
    parameter _ves is ship,
              _body is Ship:body.

    return (Constant:G * _body:Mass) / (_ves:Body:Radius + _ves:Altitude)^2.
}
// #endregion

// -- Ship Staging
// #region

// ArmAutoStaging :: (<scalar>) -> <none>
// Creates a trigger for staging based on engine thrust, with optional param to unregister at a stage number
global function ArmAutoStaging
{
    parameter stopAtStg is -1.
    
    if stopAtStg = -1 
    {
        if Core:Tag:Split("|"):Length > 0 set stopAtStg to Core:Tag:Split("|")[1]:ToNumber(0).
    }
    else
    {
        set stopAtStg to 0.
    }

    when Ship:Availablethrust <= 0.01 and throttle > 0 then
    {
        OutInfo2("Staging:" + Stage:Number).
        local startTime to Time:Seconds.
        SafeStage().
        local endTime to Time:Seconds.
        local stgTime to endTime - startTime.
        set g_stagingTime to g_stagingTime + stgTime.
        set g_staged to true.
        wait 0.1.
        OutInfo2("Staging time: " + round(g_stagingTime, 2)).
        if Ship:Availablethrust >= 0.01 set g_stagingTime to 0.
        //set g_MECO to g_MECO + (endTime - startTime).
        if Stage:Number > stopAtStg preserve.
    }
}

// ArmAutoStaging_next :: (<scalar>) -> <none>
// Creates a trigger for staging based on fuel flow, with optional param to unregister at a stage number
global function ArmAutoStaging_Next
{
    parameter stopAtStg is -1.
    
    if stopAtStg = -1 
    {
        if Core:Tag:Split("|"):Length > 0 set stopAtStg to Core:Tag:Split("|")[1]:ToNumber(0).
    }
    else
    {
        set stopAtStg to 0.
    }
    
    global stgTrk to stage:number.
    global g_engs to GetEngines().
    global g_actEngs to GetEngines("Active").
    global g_flowRate to GetEnginesFuelFlow(g_actEngs).
    
    local flowThresh to 0.

    when throttle > 0 then
    {
        if stgTrk > stage:number 
        {
            set g_engs to GetEngines("Active,Next").
            set g_flowRate to GetEnginesFuelFlow(g_actEngs).
            set flowThresh to g_flowRate[1] * 0.001.
            set stgTrk to stage:number.
        }
        else
        {
            set g_flowRate to GetEnginesFuelFlow(g_actEngs).
        }

        if g_flowRate <= flowThresh and throttle > 0
        {
            OutInfo2("Staging:" + Stage:Number).
            local startTime to Time:Seconds.

            SafeStage().
            local endTime to Time:Seconds.
            local stgTime to endTime - startTime.
            set g_stagingTime to g_stagingTime + stgTime.
            set g_staged to true.
            wait 0.02.
            OutInfo2("Staging time: " + round(g_stagingTime, 2)).
            if g_flowRate > 0 set g_stagingTime to 0.
            //set g_MECO to g_MECO + (endTime - startTime).
        }

        if Stage:Number > stopAtStg 
        {
            preserve.
        }
    }
}

local function GetEnginesFuelFlow
{
    parameter engList.

    if engList:length > 0 
    {
        local fuelFlow      to 0.
        local fuelFlowMax   to 0.
        local fuelFlowPct   to 0.
        local massFlow      to 0.
        local massFlowMax   to 0.
        local massFlowPct   to 0.

        for eng in engList
        {
            set fuelFlow    to fuelFlow + eng:fuelFlow.
            set fuelFlowMax to fuelFlowMax + eng:maxFuelFlow.
            set fuelFlowPct to round(fuelFlow / fuelFlowMax, 5).
            set massFlow    to massFlow + eng:massFlow.
            set massFlowMax to massFlowMax + eng:maxMassFlow.
        }

        return list(fuelFlow, fuelFlowMax, fuelFlowPct, massFlow, massFlowMax, massFlowPct).
    }
    return list().
}

local function GetStageFuelFlow
{
    parameter stg to stage:number.

    local fuelFlow to 0.
    
    local engList to GetEnginesByStage(stg).
    for eng in engList
    {
        set fuelFlow to fuelFlow + eng:fuelFlow.
    }
    return fuelFlow.
}

local function GetStageFuelFlowMax
{
    parameter stg to stage:number.

    local fuelFlow to 0.
    local fuelFlowMax to 0.
    
    local engList to GetEnginesByStage(stg).
    for eng in engList
    {
        set fuelFlow to fuelFlow + eng:fuelFlow.
        set fuelFlowMax to fuelFlowMax + eng:maxFuelFlow.
    }
    return list(fuelFlow, fuelFlowMax).
}

local function GetStageMassFlow
{
    parameter stg to stage:number.

    local massFlow to 0.
    local massFlowMax to 0.

    local engList to GetEnginesByStage(stg).
    for eng in engList
    {
        set massFlow to massFlow + eng:massFlow.
        set massFlowMax to massFlowMax + eng:maxMassFlow.
    }

    return list(massFlow, massFlowMax).
}

// SafeStage :: <string> -> <scalar>
// Performs a staging operation, and returns the time it took to complete staging.
// Checks for whether this is only a sepmotor stage, and stages again if so. 
// Also checks whether current engines are deployable, and adds more wait time to allow for engine deployment
global function SafeStage
{
    local onlySep to true.
    wait 0.5. 
    until false
    {
        until Stage:Ready
        {
            wait 0.05.
        }
        stage.
        break.
    }
    // Check for special conditions
    local engList to GetEnginesByStage(Stage:Number, true).
    if engList:Length > 0
    {
        if Ship:AvailableThrust > 0
        {
            for eng in engList
            {
                if not sepList:Contains(eng:Name)
                {
                    set onlySep to false.
                }
            }

            if onlySep
            {
                until false
                {
                    wait 0.50.
                    if Stage:Ready break.
                }
                stage.
            }
        }
        wait 0.25.

        if engList:Length > 0 
        {
            for eng in engList
            {
                if eng:hasModule("ModuleDeployableEngine") 
                {
                    wait until eng:Thrust > 0.
                }
            }
        }
    }
}

// Check for staging via g_staged var. If true, reset vBounds.
global function ResetStagedStatus
{
    set g_staged to false.
    return Ship:Bounds.
}
// #endregion

// -- Fairings
// #region

// 🎅 Seasons Yeetings Fairings 🎄--
// ArmFairingJettison :: <string>, <scalar>, <string> -> <none>
// Arms fairings that are tagged 
global function ArmFairingJettison
{
    parameter mode is "alt+", 
              jettisonVal is body:atm:height - 10000,
              deployTag is "ascent".


    if (ship:ModulesNamed("ModuleProceduralFairing"):length > 0)
    {
        local fairingsToArm to list().

        if deployTag:length > 0
        {
            set deployTag to "fairing." + deployTag.
        }

        for m in ship:modulesNamed("ModuleProceduralFairing")
        {
            if m:part:tag:MatchesPattern(deployTag) fairingsToArm:add(m).
        }

        if fairingsToArm:length > 0 
        {
            if mode = "alt+"
            {
                when ship:altitude > jettisonVal then
                {
                    for m in fairingsToArm
                    {
                        m:DoEvent("deploy").
                    }
                }
            }
            else if mode = "alt-"
            {
                when ship:altitude < jettisonVal then
                {
                    for m in fairingsToArm
                    {
                        m:DoEvent("deploy").
                    }
                }
            }
            // TODO - Deployment based on atmo pressure
            else if mode = "pres+"
            {
                when body:atm:altitudepressure(ship:altitude) > jettisonVal then
                {
                    for m in fairingsToArm
                    {
                        m:DoEvent("deploy").
                    }
                }
            }
            else if mode = "pres-"
            {
                when body:atm:altitudepressure(ship:altitude) > jettisonVal then
                {
                    for m in fairingsToArm
                    {
                        m:DoEvent("deploy").
                    }
                }
            }
        }
    }
}

// -- Drop tanks
// #region

// ArmDropTanks :: <[string]]> -> <bool>
// Arms drop tanks on the vessel to be decoupled when empty. 
// Defaults to parts tagged "dropTank.*", but can be overridden with 
// optional param (ex: "munAscentDropTanks.*")
global function ArmDropTanks
{
    parameter tankSet to "dropTanks".

    local tankDecouplers to Ship:PartsTaggedPattern(tankSet + ".*").
    local tankLex to lex().

    if tankDecouplers:Length > 0 
    {
        // Setup tankLex, which contains decouplers in lists ordered by idx key
        for p in tankDecouplers
        {
            // Make sure it's a decoupler!
            if p:IsType("Decoupler")
            {
                local pIdx to p:Tag:Split(".")[1].
                if tankLex:HasKey(pIdx)
                {
                    tankLex[pIdx]:Add(p).
                }
                else 
                {
                    set tankLex[pIdx] to list(p).
                }
            }
        }

        for idx in tankLex:Keys
        {
            // Make sure the idx is a number to avoid crashes
            if idx:IsType("Scalar")
            {
                // For some reason, need to assign the idx to a local var so the trigger works correctly
                local dtIdx to idx.

                // Now we define the triggers for each idx
                // The trigger monitors the first child part for resource exhaustion
                when tankLex[dtIdx][0]:Children[0]:Resources[0]:Amount <= 0.1 then
                {
                    // Iterate through the decouplers for the idx key
                    for dc in tankLex[dtIdx]
                    {
                        // Are there any separation motors that are child parts of the decoupler?
                        // If so, activate them. This is to ensure clean separation of heavy tanks.
                        if dc:PartsDubbedPattern("sep"):Length > 0 
                        {
                            for sep in dc:PartsDubbedPattern("sep") sep:activate.
                        }
                        // Get the correct decoupler module
                        local m to choose "ModuleDecouple" if dc:ModulesNamed("ModuleDecoupler"):Length > 0 else "ModuleAnchoredDecoupler".
                        // Decouple
                        if dc:modules:Contains(m) DoEvent(dc:GetModule(m), "decouple").
                    }
                    OutInfo("Drop tanks [idx:" + dtIdx + "] detached").
                    wait 1.
                    OutInfo().
                }
            }
        }

    }
}
// #endregion


// -- Parts Lists / Lexicons
// #region

// GetBoosters :: <[scalar]> -> <lexicon>
// Checks for detachable boosters on the vessel.
// By default, checks all stages, but can be overridden by param to stop 
// at a given stage.
global function GetBoosters
{
    parameter stopAtStg is 0.

    local boosterLex to lex().
    local boosterList to Ship:PartsTaggedPattern("booster.").

    // Did we find any boosters?
    if boosterList:Length > 0
    {
        for p in boosterList
        {
            // Stage check - makes sure that boosters being assigned to the lexicon 
            // are within the stages we want
            if p:Stage >= stopAtStg
            {
                local pIdx to -1.
                local pAct to "".

                // Parse the tag.
                // [0]   - Identifies it as a booster
                // [1]   - Identifies the booster separation group number (0 = first)
                // <[2]> - Potential action. Currently only 'as'/'airstart' are supported
                local tagParts to p:Tag:Split(".").
                if tagParts:Length > 1 set pIdx to p:Tag:Split(".")[1]:ToNumber(-1).
                if tagParts:Length > 2 set pAct to p:Tag:Split(".")[2].

                // Since booster tags are applied to decouplers and not the tanks / SRBs themselves,
                // check that the part is a decoupler and that it has a valid idx in the tag
                if pIdx > -1 and p:IsType("decoupler")
                {
                    if boosterLex:HasKey(pIdx) 
                    {
                        boosterLex[pIdx]:Add(p).
                    }
                    else
                    {
                        set boosterLex[pIdx] to list(p).
                    }
                }

                // Look for any boosters with airstart actions
                if pAct = "as" or pAct = "airstart" and p:IsType("engine")
                {
                    // Add it to the object under "airstart"
                    if boosterLex:HasKey("airstart")
                    {
                        if boosterLex["airstart"]:HasKey(pIdx) 
                        {
                            boosterLex["airstart"][pIdx]:Add(p).
                        }
                        else
                        {
                            set boosterLex["airstart"][pIdx] to list(p).
                        }
                    }
                    else
                    {
                        set boosterLex["airstart"] to lex(pIdx, list(p)).
                    }
                }
            }
        }
    }
    
    return boosterLex.
}
// #endregion

// Tag Functions
// Primarily parses core tags

// ParseTag :: [<string>Tag] -> Lex<String, Number>
// Splits a tag string by ':' and returns the resulting list
// Default tag is the current core
global function ParseTag
{
    parameter _tag to core:tag.

    local tagLex to lexicon().
    local tagSplit to _tag:split("|").
    set tagLex["Mission"] to tagSplit[0]:split(":").
    set tagLex["StageLimit"] to tagSplit[1]:ToNumber(0).

    return tagLex.
}

// #endregion