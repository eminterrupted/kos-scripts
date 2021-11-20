@lazyGlobal off.

// Dependencies

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
    "B9.Engine.T2A.SRBS.Jr"
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

    if orientation = "pro-sun"
    {
        return lookDirUp(ship:prograde:vector, sun:position).
    }
    else if orientation = "sun-pro" 
    {
        return lookDirUp(sun:position, ship:prograde:vector).
    }
    else if orientation = "pro-radOut"
    {
        return lookDirUp(ship:prograde:vector, -body:position).
    }
    else if orientation = "pro-body"
    {
        return lookDirUp(ship:prograde:vector, body:position).
    }
    else 
    {
        return ship:facing.
    }
    
}
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
        set charge to ship:resources:ec.
        wait 1.
        set draw to charge - ship:resources:ec.
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
    local stgFuelMass to 0.
    local stgShipMass to 0.
    
    for p in ship:parts
    {
        if p:typeName = "Decoupler" 
        {
            if p:stage <= stg set stgShipMass to stgShipMass + p:mass.
            if p:stage = stg set stgMass to stgMass + p:mass.
        }
        else if p:decoupledIn <= stg
        {
            set stgShipMass to stgShipMass + p:mass.
            if p:decoupledIn = stg 
            {
                set stgMass to stgMass + p:mass.
            }
        }

        if p:decoupledIn = stg - 1 and p:resources:length > 0 
        {
            for r in p:resources
            {
                if resList:contains(r:name) 
                {
                    // print "Calculating: " + r:name.
                    set stgFuelMass to stgFuelMass + (r:amount * r:density).
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
    local engs to list().
    list engines in engs.

    if engState = "active"  
    {
        for e in engs
        {
            if includeSep
            {
                if e:ignition and not e:flameout engList:add(e).
            }
            else if not sepList:contains(e) or e:tag = ""
            {
                if e:ignition and not e:flameout engList:add(e).
            }
        }
    }
    else if engState = "off"
    {
        for e in engs
        {
            if includeSep
            {
                if not e:ignition engList:add(e).
            }
            else if not sepList:contains(e) or e:tag = ""
            {
                if not e:ignition engList:add(e).
            }
        }
    }
    else 
    {
        if not includeSep
        {
            for e in engs
            {
                if not sepList:contains(e) or e:tag = ""
                {
                    engList:add(e).
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

    local engList to list().
    local stgEngs to list().

    list engines in engList.
    for e in engList
    {
        if e:stage = stg
        {
            if not includeSep
            {
                if not sepList:contains(e:name) stgEngs:add(e).
            }
            else
            {
                stgEngs:add(e).
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
                thrType is "curr".

    local stgThr to 0.
    local engList to list().
    list engines in engList.

    if thrType = "curr"
    {
        for e in engList 
        {
            if e:stage = stg set stgThr to stgThr + e:thrust.
        }
    }
    else if thrType = "max" 
    {
        for e in engList 
        {
            if e:stage = stg set stgThr to stgThr + e:maxThrust.
        }
    }
    else if thrType = "avail" 
    {
        for e in engList 
        {
            if e:stage = stg set stgThr to stgThr + e:availableThrust.
        }
    }
    else if thrType = "poss"
    {
        for e in engList 
        {
            if e:stage = stg set stgThr to stgThr + e:possibleThrust.
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

    if engList:length > 0
    {
        if thrType = "curr"
        {
            for e in engList set totThr to totThr + e:thrust.
        }
        else if thrType = "max" 
        {
            for e in engList set totThr to totThr + e:maxThrust.
        }
        else if thrType = "avail" 
        {
            for e in engList set totThr to totThr + e:availableThrust.
        }
        else if thrType = "poss"
        {
            for e in engList set totThr to totThr + e:possibleThrust.
        }
        return totThr.
    }
    else
    {
        return 0.
    }
}

// GetTotalISP :: (<list>Engines) -> <scalar>
// Returns averaged ISP for a list of engines
global function GetTotalIsp
{
    parameter engList.

    local relThr to 0.
    local totThr to 0.
    local stg to 0.
    for e in engList
    {
        set stg to e:stage.
        set totThr to totThr + e:possibleThrust.
        set relThr to relThr + (e:possibleThrust / e:visp).
    }

    // clrDisp(30).
    // print "GetTotalIsp                    " at (2, 30).
    // print "stg: " + stg.
    // print "totThr: " + totThr at (2, 31).
    // print "relThr: " + relThr at (2, 32).
    //Breakpoint().
    if totThr = 0
    {
        return 0.001.
    }
    else
    {
        return totThr / relThr.
    }
}

// GetExhVel :: (<list>Engines) -> <scalar>
// Returns the averaged exhaust velocity for a list of engines
global function GetExhVel
{
    parameter engList.

    return constant:g0 * GetTotalIsp(engList).
}
// #endregion

// -- Ship Triggers
// #region

    // ArmAutoStaging :: (<scalar>) -> <none>
    // Creates a trigger for staging, with optional param to unregister at a stage number
    global function ArmAutoStaging
    {
        parameter stopAtStg is 0.
        
        when ship:availablethrust <= 0.01 and throttle > 0 then
        {
            local startTime to Time:seconds.

            OutInfo("AutoStage Mode").
            wait 0.50.
            until stage:ready
            {
                wait 0.01.
            }
            stage.
            wait 0.50.
            OutInfo().
            local endTime to Time:seconds.

            set MECO to MECO + (endTime - startTime).
            if stage:number > stopAtStg preserve.
        }
        stage.
        wait 0.50.
        OutInfo().
        if stage:number > stopAtStg preserve.
    }
}
// #endregion
// #endregion