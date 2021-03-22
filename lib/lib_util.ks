@lazyGlobal off.

//-- Global Functions --//

//#region -- Generic functions
// Creates a breakpoint
global function breakpoint
{
    print "* Press any key to continue *" at (10, terminal:height - 2).
    terminal:input:getChar().
    print "                             " at (10, terminal:height - 2).
}
//#endregion

//#region -- List functions
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
//#endregion

//#region -- Check functions
// Checks if a value is between a range centered around 0.
global function util_check_value
{
    parameter val,
              valRange.

    if val >= -(valRange) and val <= valRange return true.
    else return false.
}

// Checks if a value is above/below the range bounds given
global function util_check_range
{
    parameter val,
              rangeLo,
              rangeHi.

    if val >= rangeLo and val <= rangeHi return true.
    else return false.
}
//#endregion

//#region -- Part modules
// Checks for an action and executes if found
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

// Checks for an event and executes if found
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

// Searches a module for events / actions
global function util_event_from_module
{
    parameter m,
              event,
              searchActions to true.

    for e in m:allEvents
    {
        if e:contains(event)
        {
            return e:replace("(callable) ", ""):replace(", is KSPEvent", "").
        }
    }

    if searchActions
    {
        for a in m:allActions
        {
            if a:contains(event)
            {
                return a:replace("(callable) ", ""):replace(", is KSPEvent", "").
            }
        }
    }
    return "".
}
//#endregion

//#region -- Warp functions
global function util_warp_trigger
{
    parameter tStamp, str is "timestamp".

    if time:seconds <= tStamp
    {   
        ag10 off.
        hudtext("Press 0 to warp to " + str, 15, 2, 20, green, false).
        on ag10 
        {
            warpTo(tStamp).
            wait until kuniverse:timewarp:issettled.
            ag10 off.
        }
    }
}

//#region -- Local functions
// Helper function for from loop in list sorting. 
local function list_step
{
    parameter c,
              sortDir.

    if sortDir = "desc" return c - 1.
    else return c + 1.
}
//#endregion