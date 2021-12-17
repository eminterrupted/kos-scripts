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
    "nesdIntRcsSep"
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
    else if orientation = "pro-body"
    {
        return lookDirUp(ship:prograde:vector, body:position).
    }
    else if orientation = "pro-radOut"
    {
        return lookDirUp(ship:prograde:vector, ObtNormal(ship:orbit)).
    }
    else if orientation = "body-pro"
    {
        return lookDirUp(body:position, ship:prograde:vector).
    }
    else if orientation = "sun-pro" 
    {
        return lookDirUp(sun:position, ship:prograde:vector).
    }
    else if orientation = "target-sun"
    {
        return lookDirUp(target:position, sun:position).
    }
    else if orientation = "home-sun"
    {
        return lookDirUp(kerbin:position, sun:position).
    }
    else if orientation = "facing-sun"
    {
        return lookDirUp(ship:facing:vector, sun:position).
    }
    else if orientation = "radOut-radOut"
    {
        return lookDirUp(ObtNormal(ship:orbit), -body:position).
    }
    else if orientation = "radOut-sun"
    {
        return lookDirUp(ObtNormal(ship:orbit), sun:position).
    }
    else
    {
        return ship:facing.
    }
    
}

// global function GetRollDegrees
// {
//     local rollAng to ship:facing:roll - ship:prograde:roll.
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

    //ISSUE: stgFuelMass appears to be about half (or at least, lower than) 
    //what it should be
    local stgFuelMass to 0.
    local stgShipMass to 0.
    
    local stgEngs to GetEnginesByStage(stg).
    local engResUsed to list().
    for e in stgEngs
    {
        for k in e:consumedResources:keys 
        {
            if not engResUsed:contains(k) engResUsed:add(k:replace(" ", "")).
        }
    }

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
                if engResUsed:contains(r:name) 
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
    local engs to buildList("engines").
    
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

    local engList to buildList("engines").
    local stgEngs to list().

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
              thrType is "curr",
              includeSep is false.

    local stgThr to 0.
    local engList to buildList("engines").

    for e in engList
    {
        if e:stage = stg
        {
            if not includeSep
            {
                if not sepList:contains(e:name)
                {
                    if thrType = "curr"         set stgThr to stgThr + e:thrust.
                    else if thrType = "max"     set stgThr to stgThr + e:maxThrust.
                    else if thrType = "avail"   set stgThr to stgThr + e:availableThrust.
                    else if thrType = "poss"    set stgThr to stgThr + e:possibleThrust.
                }
            }
            else
            {
                if thrType = "curr"         set stgThr to stgThr + e:thrust.
                else if thrType = "max"     set stgThr to stgThr + e:maxThrust.
                else if thrType = "avail"   set stgThr to stgThr + e:availableThrust.
                else if thrType = "poss"    set stgThr to stgThr + e:possibleThrust.
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
    parameter engList, 
              mode is "vac".

    local relThr to 0.
    local totThr to 0.

    local engIsp to { 
        parameter e. 
        if mode = "vac" return e:visp.
        if mode = "sl" return e:slisp.
        if mode = "cur" return e:ispAt(body:atm:altitudePressure(ship:altitude)).
    }.

    if engList:length > 0 
    {
        for e in engList
        {
            set totThr to totThr + e:possibleThrust.
            set relThr to relThr + (e:possibleThrust / engIsp(e)).
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

    return constant:g0 * GetTotalIsp(engList, mode).
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
        SafeStage().
        wait 0.25.
        local endTime to time:seconds.
        set g_MECO to g_MECO + (endTime - startTime).
        if stage:number > stopAtStg preserve.
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
        until stage:ready
        {
            wait 0.25.
        }
        stage.
        break.
    }
    // Check for special conditions
    local engList to GetEnginesByStage(stage:number, true).
    if engList:length > 0
    {
        if ship:availableThrust > 0
        {
            for eng in engList
            {
                if not sepList:contains(eng:name)
                {
                    set onlySep to false.
                }
            }

            if onlySep
            {
                until false
                {
                    wait 0.50.
                    if stage:ready break.
                }
                stage.
            }
        }
        wait 0.25.

        if engList:length > 0 
        {
            for eng in engList
            {
                if eng:hasModule("ModuleDeployableEngine") 
                {
                    wait until eng:thrust > 0.
                }
            }
        }
    }
}
// #endregion
// #endregion