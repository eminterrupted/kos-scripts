@lazyGlobal off.

//-- Global Functions --//

//-- Generic functions

// Checks if a value is between a range
global function util_check_value_range
{
    parameter val,
              valRange.

    if val >= -(valRange) and val <= valRange return true.
    else return false.
}

//-- Ship functions

// Returns a list of active engines
global function util_active_engines
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
global function util_active_thrust
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

// Returns whether the ship's roll error is marginal
global function util_roll_settled
{
    return util_check_value_range(steeringManager:rollError, 0.1).
}

// Safe staging
global function util_stage
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

// Jettison fairings
global function util_jettison_fairings
{
    for m in ship:modulesNamed("ProceduralFairingDecoupler")
    {
        util_do_event(m, "jettison fairing").
    }
}

//-- Part modules

// Given a module, action name, and action state (bool), 
// checks for the action and executes if found
global function util_do_action
{
    parameter m, 
              action, 
              state is true.

    if m:hasAction(action)
    {
        m:doAction(action, state).
        return true.
    }
    else
    {
        return false.
    }
}

// Given a module and event name, checks for that event and 
// executes if found
global function util_do_event
{
    parameter m, 
              event.

    if m:hasEvent(event)
    {
        m:doEvent(event).
        return true.
    }
    else
    {
        return false.
    }
}

//-- List functions

// Sorts a list of parts by stage
// Possible sortDir values: asc, desc
global function util_sort_list_by_stage
{
    parameter inList
              ,sortDir is "desc".

    local outList    to list().
    local startCount to choose -1 if sortDir = "asc" else stage:number.
    local endCount   to choose stage:number if sortDir = "asc" else -1.

    from { local c to startCount.} until c = endCount step { set c to list_step(c, sortDir). } do
    {
        for p in inList 
        {
            if p:stage = c
            {
                outList:add(p).
            }
        }
    }
    return outList.
}

//-- Local functions --//

// Helper function for from loop in list sorting. 
local function list_step
{
    parameter c,
              sortDir.

    if sortDir = "desc" return c - 1.
    else return c + 1.
}