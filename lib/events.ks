// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Event Loop Execution and Parsing
    // #region
    
    // ExecLoopEventDelegates :: <none> -> <none>
    // If there are events registered in g_LoopDelegates, this executes them
    global function ExecGLoopEvents
    {
        local EventSet to g_LoopDelegates["Events"].
        local repeatEvent to false.
        
        for ev in EventSet:Keys
        {
            if GetLoopEventResult(EventSet[ev])
            {
                // result indicates whether to preserve
                set repeatEvent to DoLoopEventAction(EventSet[ev]).
                if not repeatEvent 
                {
                    UnregisterLoopEvent(EventSet[ev]:ID).
                }
            }
        }
    }
    // #endregion

    // *- Event registration and creation
    // #region
    global function CreateLoopEvent
    {
        parameter _id,
                  _type,
                  _params is list(),
                  _check is { return true.},
                  _action is { return false.}.


        set g_Program to 2320.

        OutInfo("CreateLoopEvent: Creating new event ({0})":Format(_id)).

        local newEvent to lexicon(
            "ID",           _id
            ,"Type",        _type
            ,"Delegates",   lexicon(
                "Check",    _check@
                ,"Action",  _action@
            )
            ,"Params",      _params
            ,"Repeat",      false
        ).

        return newEvent.
    }

    global function DoLoopEventAction
    {
        parameter _eventData.

        local repeatFlag to true.

        if _eventData:HasKey("Delegates")                  
        {
            if _eventData:Delegates:HasKey("Action")
            {
                return _eventData:Delegates:Action:Call(_eventData:Params).
            }
        }
        return repeatFlag.
    }

    global function GetLoopEventResult
    {
        parameter _eventData.

        local loopResult to false.

        if _eventData:HasKey("Delegates")                  
        {
            if _eventData:Delegates:HasKey("Check")
            {
                return _eventData:Delegates:Check:Call(_eventData:Params).
            }
        }
        return loopResult.
    }

    // Register an event created in CreateEvent
    global function RegisterLoopEvent
    {
        parameter _eventData,
                  _idOverride is "*NA*".

        local localID to choose _eventData:id if _idOverride = "*NA*" else _idOverride.

        OutInfo("RegisterLoopEvent: Adding event ({0})":Format(localID)).

        if not g_LoopDelegates:HasKey("Events")
        {
            set g_LoopDelegates["Events"] to lexicon().
        }


        local doneFlag to false.
        from { local i to 0.} until doneFlag = true or i > g_LoopDelegates:Events:Keys:Length step { set i to i + 1.} do
        {
            // local namePair to "{0}_{1}":Format(localID, i:ToString()).
            if not g_LoopDelegates:Events:HasKey(localID)
            {
                g_LoopDelegates:Events:Add(localID, _eventData).
                set doneFlag to true.
                if g_LoopDelegates:HasKey("RegisteredEventTypes")
                {
                    if g_LoopDelegates:RegisteredEventTypes:HasKey(_eventData:type)
                    {
                        //set g_LoopDelegates:RegisteredEventTypes[_eventData:type] to g_LoopDelegates:RegisteredEventTypes[_eventData:type] + 1.

                        local evLastTypeVal to g_LoopDelegates:RegisteredEventTypes[_eventData:Type].
                        OutDebug("evTypeLast: [{0} ({1})]":Format(evLastTypeVal, evLastTypeVal:TypeName), 12).
                        local evNewTypeVal to evLastTypeVal + 1.
                        g_LoopDelegates:RegisteredEventTypes:Remove(_eventData:type).
                        g_LoopDelegates:RegisteredEventTypes:Add(_eventData:type, evNewTypeVal).
                    }
                    else
                    {
                        g_LoopDelegates:RegisteredEventTypes:Add(_eventData:type, 1).
                    }
                }
                else
                {
                    g_LoopDelegates:Add("RegisteredEventTypes", Lexicon(_eventData:type, 1)).
                }
            }
        }

        return doneFlag.
    }


    global function UnregisterLoopEvent
    {
        parameter _eventID.

        OutInfo("UnregisterLoopEvent: Removing event ({0})":Format(_eventID)).

        if g_LoopDelegates:Events:Keys:Contains(_eventID)
        {
            local type to g_LoopDelegates:Events[_eventID]:type.
            local typeCount to choose g_LoopDelegates:RegisteredEventTypes[type] if g_LoopDelegates:RegisteredEventTypes:HasKey(type) else 0.
            g_LoopDelegates:Events:Remove(_eventID).
            if typeCount > 0
            {
                g_LoopDelegates:RegisteredEventTypes:Remove(type).
                g_LoopDelegates:RegisteredEventTypes:Add(type, (typeCount - 1)).
                if g_LoopDelegates:RegisteredEventTypes[type] = 0
                {
                    g_LoopDelegates:RegisteredEventTypes:Remove(type).
                }
            }
        }
        return g_LoopDelegates:Events:Keys:Contains(_eventID).
    }
    // #endregion
// #endregion