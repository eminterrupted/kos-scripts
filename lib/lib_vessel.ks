@lazyGlobal off.

//-- Dependencies --//
runOncePath("0:/lib/lib_util").

//-- Variables --//
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

//-- Functions --//

//#region -- Engines
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

// Returns summed thrust for provided engines at the current throttle 
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

// Returns a list of engines that are in the currently activated stage
global function ves_stage_engines
{
    local engList to list().
    local stgList to list().
    list engines in engList.

    for e in engList 
    {
        if e:stage >= stage:number 
        {
            stgList:add(e).
        }
    }
    return stgList.
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
            set relThr to relThr + (e:possibleThrust / e:visp).
        }
    }
    
    if stgThr = 0 
    {
        return 0.
    }
    else
    {
        return stgThr / relThr.
    }
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
//#endregion

//#region -- Mass
// ToDo: Return fuel mass for a given stage
global function ves_stage_fuel_mass
{
    parameter stg.

    local stgFuelObj to lex().

    for p in ship:parts
    {
        if p:decoupledIn = stg - 1
        {
            if p:resources:length > 0
            {
                for r in p:resources
                {
                    if stgFuelObj:hasKey(r:name) 
                    {
                        set stgFuelObj[r:name] to stgFuelObj[r:name] + (r:amount * r:density).
                    }
                    else
                    {
                        set stgFuelObj[r:name] to r:amount * r:density.
                    }
                }
            }
        }
    }
    return stgFuelObj.
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

// Returns the current and dry mass for a given stage for DV calcs
// Uses stg - 1 because engines are always a stage ahead of part stage
// numbers
global function ves_mass_for_stage 
{
    parameter stg.

    local curMass to 0.
    local dryMass to 0.

    for p in ship:parts
    {
        if p:decoupledIn = stg - 1
        {
            set curMass to curMass + p:mass.
            set dryMass to dryMass + p:dryMass.
        }
        else if p:typename = "decoupler" and p:stage = stg - 1
        {
            set curMass to curMass + p:mass.
            set dryMass to dryMass + p:dryMass.
        }
    }

    return list(curMass, dryMass).
}
//#endregion

//#region -- Steering
// Checks whether the ship's roll error is marginal
global function ves_roll_settled
{
    return util_check_value(steeringManager:rollError, 0.125).
}

// Checks whether the steering manager has settled on target
global function ves_settled
{
    return util_check_value(steeringManager:angleError, 0.125).
}
//#endregion

//#region -- Staging
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
    
    // Stage again if currents engines are sep motors
    if ship:availablethrust > 0 
    {
        local onlySep to true.
        for e in ves_stage_engines()
        {
            if not sepList:contains(e:name)
            {
                set onlySep to false.
                break.
            }
        }
        
        if onlySep 
        {
            wait 1.
            stage.
        }
    }
    
    for e in ves_stage_engines()
    {
        if e:hasModule("ModuleDeployableEngine") 
        {
            disp_info2("Engine with ModuleDeployableEngine found").
            wait until e:thrust > 0.
            break.
        }
    }
    
    //General wait for once staging is complete
    wait 0.5.
    disp_info2().
}
//#endregion

//#region -- Translation
// Takes a vector and translates towards it
global function ves_translate
{
    parameter vec is v(0, 0, 0).

    if vec:mag > 1 set vec to vec:normalized. 

    set ship:control:fore       to vDot(vec, ship:facing:forevector).
    set ship:control:starboard  to vDot(vec, ship:facing:starvector).
    set ship:control:top        to vDot(vec, ship:facing:topvector).
}
//#endregion

//#region -- Part Module Actions
// Extend / retract antennas in a list
global function ves_activate_antenna
{
    parameter commList is ship:modulesNamed("ModuleRTAntenna"),
              state is true.

    local event to choose "activate" if state else "deactivate".
    
    for m in commList
    {       
        util_do_event(m, event).
    }
}

// Extend / retract solar panels in a list. 
global function ves_activate_solar
{
    parameter solarList is ship:modulesNamed("ModuleDeployableSolarPanel"), 
              state is true.

    local event to choose "extend solar panel" if state else "retract solar panel". 
    
    for m in solarList
    {
        util_do_event(m, event).
    }
}

// Jettison fairings
global function ves_jettison_fairings
{
    local procEvent     to "jettison fairing".
    local procFairing   to "ProceduralFairingDecoupler".

    local stEvent       to "deploy".
    local safFairing    to "ModuleSimpleAdjustableFairing".
    local stFairing     to "ModuleProceduralFairing".

    if ship:modulesNamed(procFairing):length > 0
    {
        for m in ship:modulesNamed(procFairing)
        {
            util_do_event(m, procEvent).
        }
    }
    if ship:modulesNamed(stFairing):length > 0
    {
        for m in ship:modulesNamed(stFairing)
        {
            util_do_event(m, stEvent).
        }
    }
    if ship:modulesNamed(safFairing):length > 0
    {
        for m in ship:modulesNamed(safFairing)
        {
            util_do_event(m, stEvent).
        }
    }
}
//#endregion