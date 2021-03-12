@lazyGlobal off.

//-- Global Functions --//

//-- Generic functions
// Creates a breakpoint
global function breakpoint
{
    print "*** Press 'Enter' to continue *** " at (10, 25).
    until false {
        if terminal:input:hasChar
        {
            if terminal:input:getChar = terminal:input:return
            {
                break.
            }
            else{
                terminal:input:clear.
            }
        }
        wait 0.1.
    }
}

// Checks if a value is between a range centered around 0.
global function util_check_value
{
    parameter val,
              valRange.

    if val >= -(valRange) and val <= valRange return true.
    else return false.
}

// Checks if a value is above the provided low range val and 
// below the high range val
global function util_check_range
{
    parameter val,
              valRangeLow,
              valRangeHigh.

    if val >= valRangeLow and val <= valRangeHigh return true.
    else return false.
}

//-- List functions
// Sorts a list of parts by stage
// Possible sortDir values: asc, desc
global function util_sort_list_by_stage
{
    parameter inList,
              sortDir is "desc".

    local outList    to list().
    local startCount to choose -1 if sortDir = "asc" else stage:number.
    local endCount   to choose stage:number if sortDir = "asc" else -2.

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

// Given a module and event name, checks for that event in
// the module's events and actions list. Actions because they
// usually turn into events when available
global function util_event_from_module
{
    parameter m,
              event.

    for e in m:allEvents
    {
        if e:contains(event)
        {
            return e:replace("(callable) ", ""):replace(", is KSPEvent", "").
        }
    }

    for a in m:allActions
    {
        if a:contains(event)
        {
            return a:replace("(callable) ", ""):replace(", is KSPEvent", "").
        }
    }
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