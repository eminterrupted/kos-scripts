@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/nav").

// *~ Variables ~* //
// #region

// -- Local
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

    local dirLookup to lex(
        "pro",          Ship:Prograde:Vector
        ,"prograde",    Ship:Prograde:Vector
        ,"sun",         Sun:Position
        ,"retro",       Ship:Retrograde:Vector
        ,"retrograde",  Ship:Retrograde:Vector
        ,"facing",      Ship:Facing:Vector
        ,"body",        Body:Position
        ,"bodyOut",     -Body:Position
        ,"radOut",      -Body:Position
        ,"home",        Body("Kerbin"):Position
        ,"srfRetro",    Ship:SrfRetrograde:Vector
        ,"up",          vcrs(ship:body:position - ship:position, ship:velocity:orbit):normalized
    ).
    if HasTarget set dirLookup["target"] to Target:Position.
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

// GetStageThrust :: (<list>Engines, [<string>]) -> <scalar>
// Returns summed thrust of a given type for a given stage
global function GetStageThrust
{
    parameter stg,
              thrType is "curr",
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
                    if thrType = "curr"         set stgThr to stgThr + eng:Thrust.
                    else if thrType = "max"     set stgThr to stgThr + eng:MaxThrust.
                    else if thrType = "avail"   set stgThr to stgThr + eng:AvailableThrust.
                    else if thrType = "poss"    set stgThr to stgThr + eng:PossibleThrust.
                }
            }
            else
            {
                if thrType = "curr"         set stgThr to stgThr + eng:Thrust.
                else if thrType = "max"     set stgThr to stgThr + eng:MaxThrust.
                else if thrType = "avail"   set stgThr to stgThr + eng:AvailableThrust.
                else if thrType = "poss"    set stgThr to stgThr + eng:PossibleThrust.
            }
        }
    }
    return stgThr.
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
// Creates a trigger for staging, with optional param to unregister at a stage number
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
              jettisonAlt is body:atm:height - 10000,
              deployTag is "descent".

    if deployTag:length > 0
    {
        set deployTag to "fairing." + deployTag.
    }

    if (ship:modulesnamed("ModuleProceduralFairing"):length > 0)
    {
        if mode = "alt+"
        {
            when ship:altitude > jettisonAlt then
            {
                for module in ship:modulesnamed("ModuleProceduralFairing")
                {
                    if module:part:tag:matchesPattern(deployTag)
                    {
                        module:doevent("deploy").
                        wait 0.05.
                    }
                }
            }
        }
        else if mode = "alt-"
        {
            when ship:altitude < jettisonAlt then
            {
                for module in ship:modulesnamed("ModuleProceduralFairing")
                {
                    if module:part:tag:matchesPattern(deployTag)
                    {
                        module:doevent("deploy").
                        wait 0.05.
                    }
                }
            }
        }
        // TODO - Deployment based on atmo pressure
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

// #endregion