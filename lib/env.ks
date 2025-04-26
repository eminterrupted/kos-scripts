@LazyGlobal off.

// *~ Dependencies ~* //
// #region

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

    // *- Function Group
    // #region

    // FunctionName :: (_inputParam)<type> -> (outputValue)<type>
    // Description
    // selexi :: _lex<Lexicon>, _pagePath<String> -> selPage
    // Safely returns whatever is found via the provided path following the "<parent/<child>/<etc>" format
    // Validates the path by walking it. Bails immediately if the path is not found
    global function selex
    {
        parameter _lex,
                  _pagePath.

        local selPage to _lex.

        if selPage:Keys:Length > 0
        {
            if _pagePath:Contains("/")
            {
                for _leaf in _pagePath:Split("/")
                {
                    if selPage:HasKey(_leaf) 
                    {
                        set selPage to selPage[_leaf].
                    }
                    else
                    {
                        return selPage.
                    }
                }
            }
            else
            {
                set selPage to choose selPage[_pagePath] if selPage:HasKey(_pagePath) else selPage.
            }
        }
        return selPage.
    }
    // #endregion

// #endregion