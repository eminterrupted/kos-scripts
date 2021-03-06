@lazyGlobal off.

//-- Dependencies --//
runOncePath("0:/lib/lib_util").

//-- Variables --//
local sepList to list("sepMotor1", "B9_Engine_T2_SRBS", "B9_Engine_T2A_SRBS").

//-- Ship functions --//

//-- Engines
// Returns a list of active engines
global function ves_active_engines
{
    local engineList to list().
    local activeList to list().
    list engines in engineList.
    for e in engineList
    {
        if e:ignition
        {
            activeList:add(e).
        }
    }
    return activeList.
}

// Returns summed thrust for active engines in the provided
// list, at the current throttle setting. 
global function ves_active_thrust
{
    parameter engList.
    
    local curThrust to 0.
    for e in engList
    {
        if e:ignition and not sepList:contains(e:name)
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
        if e:stage = stg and not sepList:contains(e:name)
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
        if e:stage = stg and not sepList:contains(e:name)
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
    return util_check_value(steeringManager:rollError, 0.1).
}

// Checks whether the steering manager has settled on target
global function ves_settled
{
    return util_check_value(steeringManager:angleError, 0.1).
}



//-- Staging
// Safe staging
global function ves_safe_stage
{
    wait 0.5.
    until false 
    {
        until stage:ready 
        {   
            wait 0.01.
        }
        stage.
        break.
    }
    // Check to see if the current active engines firing are only
    // separation motors. If so, wait for the separation to occur, 
    // then stage the main engine
    if ship:availablethrust > 0 
    {
        local eList to ves_active_engines().
        local onlySep to true.
        for e in eList 
        {
            if not sepList:contains(e:name)
            {
                set onlySep to false.
            }
        }
        
        if onlySep 
        {
            wait 2.5.
            stage.
        }
    }
    wait 0.5.
}

// Setup a persistent staging trigger
global function ves_staging_trigger
{
    when ship:maxThrust <= 0.1 and throttle > 0 then 
    {
        ves_safe_stage().
        preserve.
    }
}


//-- Part actions
// Extend / retract antennas in a list
// True extends, false retracts
global function ves_activate_antenna
{
    parameter commList, state is true.

    local event   to choose "activate" if state else "deactivate".
    local commMod to "ModuleRTAntenna".

    for p in commList
    {
        if p:hasModule(commMod)
        {
            util_do_event(p:getModule(commMod), event).
        }
    }
}


// Extend / retract solar panels in a list. 
// True extends, false retracts if available
global function ves_activate_solar
{
    parameter solarList, state is true.

    local event    to choose "extend solar panel" if state else "retract solar panel". 
    local solarMod to "ModuleDeployableSolarPanel".

    for p in solarList
    {
        if p:hasModule(solarMod)
        {
            util_do_event(p:getModule(solarMod), event).
        }
    }
}

// Jettison fairings
global function ves_jettison_fairings
{
    local procEvent     to "jettison fairing".
    local procFairing   to "ProceduralFairingDecoupler".

    local stEvent       to "deploy".
    local stFairing     to "ModuleProceduralFairing".

    if ship:modulesNamed(procFairing):length > 0
    {
        for m in ship:modulesNamed(procFairing)
        {
            util_do_event(m, procEvent).
        }
    }
    else if ship:modulesNamed(stFairing):length > 0
    {
        for m in ship:modulesNamed(stFairing)
        {
            util_do_event(m, stEvent).
        }
    }    
}