@lazyGlobal off.

runOncePath("0:/lib/lib_util").

//-- Ship functions --//

//-- Engines
// Returns a list of active engines
global function ves_active_engines
{
    local engList to list().
    list engines in engList.
    for e in engList
    {
        if e:ignition
        {
            engList:add(e).
        }
    }
    return engList.
}

// Returns summed thrust for active engines in the provided
// list, at the current throttle setting. 
global function ves_active_thrust
{
    parameter engList.
    
    local curThrust to 0.
    for e in engList
    {
        if e:ignition
        {
            set curThrust to curThrust + e:thrust.
        }
    }
    return curThrust.
}

// Returns the aggregate exhaust velocity for a given stage
global function ves_stage_exh_vel
{
    parameter stg.

    local stgIsp to ves_stage_isp(stg).
    return constant:g0 * stgIsp.
}

// Returns isp for a given stage
global function ves_stage_isp
{
    parameter stg.

    local relThr    to 0.
    local stgThr    to 0.
    
    local engList   to list().
    list engines in engList.

    for e in engList 
    {
        if e:stage = stg 
        {
            set stgThr to stgThr + e:possibleThrust.
            set relThr to relThr + (stgThr / e:visp).
        }
    }
    return stgThr / relThr.
}

// Returns the possible aggregate thrust for a given stage
global function ves_stage_thrust
{
    parameter stg.

    local stgThr    to 0.
    
    local engList   to list().
    list engines in engList.

    for e in engList
    {
        if e:stage = stg
        {
            set stgThr to stgThr + e:possibleThrust.
        }
    }
    return stgThr.
}



//-- Mass
// ToDo: Return fuel mass for a given stage
global function ves_stage_fuel_mass
{
    parameter stg.
    return stg.
}

// Returns the current vessel mass if the vessel was on the 
// given stage number (i.e., stg = 4, mass for stages 4 -> -1).
global function ves_mass_at_stage
{
    parameter stg.

    local curMass to 0.
    for p in ship:parts
    {
        if p:stage <= stg 
        {
            set curMass to curMass + p:mass.
        }
    }
    return curMass.
}



//-- Steering
// Checks whether the ship's roll error is marginal
global function ves_roll_settled
{
    return util_check_value_range(steeringManager:rollError, 0.1).
}

// Checks whether the steering manager has settled on target
global function ves_settled
{
    return util_check_value_range(steeringManager:angleError, 0.1).
}



//-- Staging
// Safe staging
global function ves_stage
{
    wait 0.25.
    until false {
        until stage:ready 
        {   
            wait 0.01.
        }
        wait 0.25.
        stage.
        break.
    }
}

// Setup a persistent staging trigger
global function ves_staging_trigger
{
    when ship:maxThrust <= 0.1 and throttle > 0 then 
    {
        ves_stage().
        preserve.
    }
}



//-- Misc
// Jettison fairings
global function ves_jettison_fairings
{
    local jetEvent to "jettison fairing".
    for m in ship:modulesNamed("ProceduralFairingDecoupler")
    {
        if m:hasEvent(jetEvent) m:doEvent(jetEvent).
    }
}