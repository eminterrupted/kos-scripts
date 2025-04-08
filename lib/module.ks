@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region

    // #endregion

    // *- Reference Objects
    // #region
    local pruneStrObj to lexicon(
        "BuildStr", "({0}) {1}, is {2}",
        "Pre", list(
            "callable",
            "settable"
        ),
        "Post", list(
            "KSPEvent",     // 0
            "KSPAction",    // 1
            "Boolean",      // 2
            "String",       // 3
            "Int32",        // 4
            "Double",       // 5
            "Single"        // 6
        )
    ).

    // Field values are indexes into pruneStrObj
    local l_knownModuleList to lexicon(
        "kOSProcessor", lex(
            "Actions", list(
                "open terminal",
                "close terminal",
                "toggle terminal",
                "toggle power",
                "suppress on",
                "suppress off",
                "toggle suppression"
            ),
            "Events", list(
                "open terminal",
                "close terminal",
                "toggle power"
            ),
            "Fields", lex(
                "kos disk space",    list(4, 1),
                "kos average power", list(6, 1)
            )
        ),
        "ModuleEnginesRF", lex(
            "Actions", list(
                "toggle engine", 
                "shutdown engine", 
                "activate engine", 
                "toggle independent throttle"
            ),
            "Events", list(
                "activate engine",
                "shutdown engine"
            ),
            "Fields", lex(
                "propellant",               list(1, 3),
                "predicted residuals",      list(0, 5),
                "mixture ratio",            list(0, 5),
                "ignitions remaining",      list(0, 4),
                "effective spool-up time",  list(0, 6),
                "current throttle",         list(0, 6),
                "mass flow",                list(1, 6),
                "eng. internal temp",       list(1, 5),
                "thrust",                   list(1, 6),
                "specific impulse",         list(1, 6),
                "status",                   list(1, 3),
                "throttle",                 list(1, 2),
                "spool-up",                 "effective spool-up time"
            )
        )
    ).


    // #endregion

    // *- Delegates
    // #region

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Function Group
    // #region

    // :: Global
    // #region

    // do_action :: (_m<Module>, _action<String>, [_set<Boolean>]) -> _errorLevel<uint>
    // Performs the action provided if it is present. Prunes the string if it detects it is not pruned already [starts with '(']
    global function do_action
    {
        parameter _m,
                  _action,
                  _set is True.

        local errlvl to 0.

        if _action:MatchesPattern("^\((set|cal)")
        {
            set  _action to prune_module_item_string(_action).
        }
        if _m:HasAction(_action)
        {
            _m:DoAction(_action, _set).
            set errlvl to 1.
        }
        else
        {
            set errlvl to -1.
        }

        return errlvl.
    }

    // do_event :: (_m<Module>, _event<String>) -> _errorLevel<uint>
    // Performs the event provided if it is present. Prunes the string if it detects it is not pruned already [ i.e., starts with '(set' or '(cal' ]
    global function do_event
    {
        parameter _m,
                  _event.

        local errlvl to 0.

        if _event:MatchesPattern("^\((set|cal)")
        {
            set  _event to prune_module_item_string(_event).
        }
        if _m:HasEvent(_event)
        {
            _m:DoEvent(_event).
            set errlvl to 1.
        }
        else
        {
            set errlvl to -1.
        }
        return errlvl.
    }

    // get_field :: (_m<Module>, _field<String>, [_defVal<Any>]) -> _returnValue<Any>
    // Retrieves the field provided if it is present. Prunes the string if it detects it is not pruned already [ i.e., starts with '(set' or '(cal' ]
    global function get_field
    {
        parameter _m,
                  _field,
                  _defVal is "NUL".

        if _field:MatchesPattern("^\((set|cal)")
        {
            set  _field to prune_module_item_string(_field).
        }
        if _m:HasField(_field)
        {
            return _m:GetField(_field).
        }
        else
        {
            return _defVal.
        }
    }
    
    // set_field :: (_m<Module>, _field<String>, [_defVal<Any>]) -> _returnValue<Any>
    // Retrieves the field provided if it is present. Prunes the string if it detects it is not pruned already [ i.e., starts with '(set' or '(cal' ]
    global function set_field
    {
        parameter _m,
                  _field,
                  _newVal.

        local errlvl to 0.
        local fieldObj to list().

        if _field:MatchesPattern("^\((set)")
        {
            set fieldObj to parse_module_string(_field).
        }
        else
        {
            set fieldObj to list("settable", _field).
        }

        if _m:HasField(fieldObj[1])
        {
            if fieldObj[0] = "settable"
            {
                _m:SetField(fieldObj[1], _newVal).
                if _m:GetField(fieldObj[1]) = _newVal
                {
                    set errlvl to 1.
                }
                else
                {
                    set errlvl to 2.
                }
            }
            else
            {
                set errlvl to 3.
            }
        }
        else
        {
            set errlvl to -1.
        }

        return errlvl.
    }
    
    // #endregion

    // :: Local
    // #region

    // ParseModuleString :: (_inStr)<string> -> (_outStrObj)<lexicon>
    // Takes a module item (Action, Event, Field) and returns a list featuring the three components: (ItemContext, ItemName, ItemType)
    local function parse_module_string
    {
        parameter _inStr.

        local strObj to _inStr:Replace("(",""):Split(")").
        for str in strObj[1]:Split(",") 
        { 
            strObj:Add(str:Trim:Replace("is ","")). 
        }
        
        return strObj.    
    }

    // PruneModuleString :: (_inStr)<string> -> (_outStr)<string>
    // Removes the prefix and suffix from a given module string so that it can be properly accessed
    local function prune_module_item_string
    {
        parameter _inStr.

        return _inStr:Replace("(",""):Split(")")[1]:Split(",")[0]:Trim.
    }

    // #endregion

    // #endregion

// #endregion