@LazyGlobal off.

//  Establishes the base types in common use across multiple libraries and scripts

// Types
// #region

    // Typename

// #endregion

// Methods
// #region

    // local methodDel to {}. 
    // Type.Add(methodDel@).

// #endregion



    // String types
    global StringUnitConversion to lexicon(
            "m", 1,
            "Km", 100000,
            "cm", 0.1,
            "Mm", 1000000,
            "mmm", 0.01,
            "Gm", 1000000000
        ).

    // Masks are stored as lists containing (<hex>, <dec>)
    global BitMaskRef to lex(
        "Byte", lex(
            "0000", list("0", 0 ),
            "0001", list("1", 1 ),
            "0010", list("2", 2 ),
            "0011", list("3", 3 ),
            "0100", list("4", 4 ),
            "0101", list("5", 5 ),
            "0110", list("6", 6 ),
            "0111", list("7", 7 ),
            "1000", list("8", 8 ),
            "1001", list("9", 9 ),
            "1010", list("A", 10),
            "1011", list("B", 11),
            "1100", list("C", 12),
            "1101", list("D", 13),
            "1110", list("E", 14),
            "1111", list("F", 15)
        ),
        "Hex", lex(
            "0", list("0000", 0 ),
            "1", list("0001", 1 ),
            "2", list("0010", 2 ),
            "3", list("0011", 3 ),
            "4", list("0100", 4 ),
            "5", list("0101", 5 ),
            "6", list("0110", 6 ),
            "7", list("0111", 7 ),
            "8", list("1000", 8 ),
            "9", list("1001", 9 ),
            "A", list("1010", 10),
            "B", list("1011", 11),
            "C", list("1100", 12),
            "D", list("1101", 13),
            "E", list("1110", 14),
            "F", list("1111", 15)
        ),
        "Dec", lex(
            0 , list("0000", "0"),
            1 , list("0001", "1"),
            2 , list("0010", "2"),
            3 , list("0011", "3"),
            4 , list("0100", "4"),
            5 , list("0101", "5"),
            6 , list("0110", "6"),
            7 , list("0111", "7"),
            8 , list("1000", "8"),
            9 , list("1001", "9"),
            10, list("1010", "A"),
            11, list("1011", "B"),
            12, list("1100", "C"),
            13, list("1101", "D"),
            14, list("1110", "E"),
            15, list("1111", "F")
        )
    ).
// #endregion

// Methods
// #region

// #endregion