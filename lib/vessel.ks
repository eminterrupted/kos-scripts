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
        return lookDirUp(ship:prograde:vector, VesTangent(ship)).
    }
    else if orientation = "pro-body"
    {
        return lookDirUp(ship:prograde:vector, body:position).
    }
    else if orientation = "radOut-radOut"
    {
        return lookDirUp(VesNormal(ship), -body:position).
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

// -- Ship Staging
// #region

// ArmAutoStaging :: (<scalar>) -> <none>
// Creates a trigger for staging, with optional param to unregister at a stage number
global function ArmAutoStaging
{
    parameter stopAtStg is 0.
    
    when ship:availablethrust <= 0.01 and throttle > 0 then
    {
        local startTime to time:seconds.
        OutInfo("[" + stage:number + "] AutoStage Mode").
        SafeStage().
        wait 0.25.
        local endTime to time:seconds.
        set g_MECO to g_MECO + (endTime - startTime).
        print "[" + stage:number + "] stopAtStage: " + stopAtStg at (2, 25).
        print "[" + stage:number + "] CurStage" at (2, 26).
        print "[" + stage:number + "] Expression: " + (stage:number >= stopAtStg) at (2, 27).
        if stage:number >= stopAtStg preserve.
    }
}

// SafeStage :: <string> -> <scalar>
// Performs a staging operation, and returns the time it took to complete staging.
// Checks for whether this is only a sepmotor stage, and stages again if so. 
// Also checks whether current engines are deployable, and adds more wait time to allow for engine deployment
global function SafeStage
{
    parameter mode is "".

    local onlySep to true.
    local stg to stage:number.
    OutInfo2("Staging (" + stg + ")").
    wait 0.5. 
    until false
    {
        if stage:ready
        {
            stage.
            break.
        }
        wait 0.25.
    }
    print "[" + stg + "] Stage " + stg + "  " at (2, 28).

    // Check for special conditions
    local engList to GetEnginesByStage(stg).
    
    print "[" + stg + "] Ship:availableThrust: " + round(ship:availablethrust, 1) at (2, 29).
    if ship:availableThrust > 0
    {
        print "[" + stg + "] Passed ship:availablethrust check" at (2, 30).
        for eng in engList
        {
            if not sepList:contains(eng:name)
            {
                set onlySep to false.
            }
        }

        print "[" + stg + "] onlySep: " + onlySep at (2, 31).
        if onlySep
        {
            wait 0.50.
            stage.
            wait 0.50.
        }
    }

    print "[" + stg + "] engList:length: " + engList:length at (2, 32).
    if engList:length > 0 
    {
        for eng in engList
        {
            if eng:hasModule("ModuleDeployableEngine") 
            {
                OutInfo2("Deploying engine").
                wait until eng:thrust > 0.
            }
        }
    }
    print "[" + stg + "] Returning from SafeStage()" at (2, 33).
}
// #endregion
// #endregion