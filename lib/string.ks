@LazyGlobal off.

// *~ Dependencies ~* //
// #region

RunOncePath("0:/env/types/_init.ks").
// #include "0:/env/types/string_types.ks"

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region

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

    // *- String parsing
    // #region

    // parse_string_scalar
    global function parse_string_scalar 
    {
        parameter _inputString,
                  _fallbackValue is 0.

        local scalar_result to -1.
        
        if _inputString:IsType("Scalar") // if it's already a scalar, well...
        {
            set scalar_result to _inputString.
        }
        else
        {
            if _inputString:MatchesPattern("\d+(\.\d+)?((K|k)m$|(M|m)m$)+")
            {
                if _inputString:MatchesPattern("(^\d+(\.\d+)?((K|k)m$))")
                {
                    set scalar_result to _inputString:Replace("km", ""):Replace("Km", ""):ToNumber(_fallbackValue) * 1000.
                }
                else if _inputString:MatchesPattern("(^\d+(\.\d+)?((M|m)m$))")
                {
                    set scalar_result to _inputString:Replace("mm", ""):Replace("Mm", ""):ToNumber(_fallbackValue) * 1000000.
                }
            }
            else if _inputString:MatchesPattern("(^\d*)[dhmsDHMS]+")
            {
                set scalar_result to 0.
                local strSet to list().
                
                for key in l_timeTable:Keys
                {
                    if _inputString:MatchesPattern("(^\d*{0})":Format(key))
                    {
                        set strSet to _inputString:Split(key).
                        set scalar_result to scalar_result + strSet[0]:ToNumber * l_timeTable[key].
                        strSet:Remove(0).
                    }
                }
            }
            else if _inputString:MatchesPattern("(\d{1,3}\.)?\d*%$")
            {
                set scalar_result to _inputString:Replace("%",""):ToNumber(_fallbackValue) / 100.
            }
            else if _inputString:MatchesPattern("(^\d*(\.\d{1,})?$)")
            {
                set scalar_result to _inputString:ToNumber(_fallbackValue).
            }
            else
            {
                set scalar_result to _inputString:ToNumber(_fallbackValue).
            }
        }
        return scalar_result.
    }

    // parse_scalar_short_string :: _inScalar<scalar> -> <String>
    // Converts a number to a shorthand string (i.e., 250000 to "250km")
    global function parse_scalar_short_string
    {
        parameter _inScalar.
        
        if _inScalar < 10000
        {
            return _inScalar:ToString.
        }
        else if _inScalar < 10000000
        {
            return "{0}Km":Format(Round(_inScalar / 1000, 2)).
        }
        else if _inScalar < 1000000000
        {
            return "{0}Mm":Format(Round(_inScalar / 1000000, 2)).
        }
        else if _inScalar <  10000000000
        {
            return "{0}Gm":Format(Round(_inScalar / 1000000000, 2)).
        }
        else return _inScalar:ToString.
    }
    // #endregion

    // *- String generation
    // #region

    // str_gen :: _inputString<String>, [_repeatCount<int>] -> outStr<String>
    // Provided an input string, will return a string contain that repeated a specific number of times
    global function str_gen {

        parameter _inputString,
                  _repeatCount is 1.

        local outStr to "".
        from { local i to 0.} until i = _repeatCount step { set i to i + 1.} do {

            set outStr to outStr + _inputString.

        }
        return outStr.

    }
    
    // #endregion

// #endregion