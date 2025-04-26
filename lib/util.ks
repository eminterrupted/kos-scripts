@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #include "0:/env/types/_base.ks"
// #include "0:/env/types/_string.ks"
// #include "0:/env/types/_term.ks"

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

    // *- Bit operations
    // #region

    // HexToCharCode :: _hexStr<string>, _charPath<string> -> outStr<string>
    // Converts a 1,2, or 4-char hex string to the appropriate bit mask
    global function HexToBitMask
    {
        parameter _hexStr,
                  _bitDepth is 0. // 0: 4 bits, 1: 8 bits, 2: 12 bits, 3: 16 bits

        local outBytes to list().
        for _ch in _hexStr
        {
            outBytes:Add(BitMaskRef:Hex[_ch]).
        }
        return outBytes:Join(" ").
    }

    // HexToChar :: _hexStr<string>, _charPath<string> -> output<string>
    // Converts a 1,2, or 4-char hex string to the appropriate string char
    global function HexToChar
    {
        parameter _hexStr,
                  _charPath.

        return char(CharCodes:Chars[_charPath]:Hex[_hexStr]).
    }

    // HexToCharCode :: _hexStr<string>, _charPath<string> -> outStr<string>
    // Converts a hex string to the appropriate character code given the proper path context
    global function HexToCharCode
    {
        parameter _hexStr,
                  _charPath.

        local selPage to CharCodes.

        if selectedCharSet:HasKey(_hexStr)
        {
            return selectedCharSet:Hex[_hexStr].
        }
        else
        {
            return -1.
        }
    }

    // ByteToHex :: _byteMask<string> -> hexStr<string>
    global function ByteToHex 
    {
        parameter _byteMask.

        local hexStr to "".
        local bytes to _byteMask:Split(" ").
        
        for _byte in bytes
        {
            set hexStr to hexStr + BitMaskRef:Byte[_byte].
        }

        return hexStr.
    }
    // #endregion

    // *- Object helpers
    // #region

    // selexi :: _lex<Lexicon>, _pagePath<String> -> selPage
    // Safely returns whatever is found via the provided path following the "<parent/<child>/<etc>" format
    // Validates the path by walking it. Bails immediately if the path is not found
    global function selexi
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

    // *- Unit conversion
    // #region

    
    
    // #endregion

    // :: Local
    // #region
    
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
    // #endregion
    
    // #endregion

// #endregion