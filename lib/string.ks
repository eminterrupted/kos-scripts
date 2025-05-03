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
    global function parse_string_scalar {

        

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