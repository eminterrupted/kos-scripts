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

// Checks if a value is between a range
global function util_check_value_range
{
    parameter val,
              valRange.

    if val >= -(valRange) and val <= valRange return true.
    else return false.
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

//-- Local functions
// Helper function for from loop in list sorting. 
local function list_step
{
    parameter c,
              sortDir.

    if sortDir = "desc" return c - 1.
    else return c + 1.
}