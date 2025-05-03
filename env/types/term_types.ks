@LazyGlobal off.

// Contains types used by the term lib and builds a "class"
// Methods are added to each class after definition

// Types
// #region

// Contains Style objects with pointers to characters needed for that style
// SetLegend: _: Default; _+: Bold; _alt: Alternate set; _<start[v|h]>+<end[v|h]> (i.e., _h+v: default horizontal, bold vertical)
global Styles to lexicon(
    "Line", lex(
        "Single", lex(
            "bdr", lex( //  (  L  ,   T  ,   R  ,   B  )
                "_",    list("1A0", "10A", "1A0", "10A"),   // Normal
                "_b",   list("1F0", "10F", "1F0", "10F")    // Bold
            ),
            "cor", lex( //  ( TL  , TR   , BR   , BL   )
                "_",    list("122", "128", "188", "182"),   // Standard 
                "_b",   list("133", "13C", "1CC", "1C3"),   // Bold
                "_r",   list("388", "382", "328", "322"),   // Rounded
                "_vb",  list("132", "138", "1C8", "1C2"),   // To Vert Bold
                "_hb",  list("123", "12C", "18C", "183"),   // To Horz Bold
                "_v2",  list("232", "238", "2C8", "2C2"),   // To Vert Double
                "_h2",  list("22C", "223", "28C", "283")    // To Horz Double
            ),
            "div", lex( //  (  L  ,   T  ,   R  ,   B  ,   C  )
                "_",    list("1A2", "12A", "1A8", "18A", "1AA"), // Standard
                "_b",   list("1F3", "13F", "1FC", "1CF", "1FF"), // Bold
                "_c", lex(
                    "vbb",  list("1B3", "1EC", "1F8", "1CA", "1FA"), // To Vert Full Bold
                    "v22",  list("1F2", "13A", "1F8", "1CA", "1FA"), // To Vert Double-Bold
                    "vbu",  list("1F2", "13A", "1F8", "1CA", "1FA"), // To Vert Upper-Bold
                    "vbl",  list("1F2", "13A", "1F8", "1CA", "1FA"), // To Vert Lower-Bold
                    
                    "hbb",  list("1A3", "12F", "1AC", "1CA", "1FA"), // To Horz Full Bold
                    "h22",  list("1A3", "12F", "1AC", "1CA", "1FA"), // To Horz Double-Bold
                    "hbu",  list("1A3", "12F", "1AC", "1CA", "1FA"), // To Horz Double-Bold
                    "hbl",  list("1A3", "12F", "1AC", "1CA", "1FA")  // To Horz Double-Bold
                )
            ),
            "spc", lex(
                "_",    list("3A2", "32A", "3AA") // Angled lines
            )
        ),
        "Bold", lex(
            "bdr", lex(
                "_",    list("10F", "1F0", "10F", "1F0")
            ),
            "cor", lex(
                "_",    list("1CC", "1C3", "13C", "133")
            ),
            "div", lex(
                "_",    list("13F", "1CF", "1FC", "1F3", "1FF")
            ),
            "spc", lex(
                "_",    list()
            )
        ),
        "Double", lex(
            "bdr", lex(
                "_",    list("20F", "2F0", "20F", "2F0")
            ),
            "cor", lex(
                "_",     list("233", "23C", "2CC", "2C3"),
                "_2v1h", list("232", "238", "2C8", "2C2"),
                "_1v2h", list("22C", "223", "28C", "283")
            ),
            "div", lex(
                "_",    list("23F", "2CF", "2FC", "2F3", "2FF"),
                "v2h1", list("2F2", "2F8", "23A", "2CA", "2AF"),
                "h2v1", list("2A3", "2AC", "22F", "28F", "2FA")
            ),
            "spc", lex(
                "_", list()
            )
        )
    )//,
    // "Glyph", lex(
    //     "Rect", lex(
    //         "Part", lex(
    //             "ver", list("F0", "80", "02", "03", "31", "0F", "1F", "3F", "7F", "FF"),
    //             "hor", list("FF", "FE", "FC", "F8", "F0", "E0", "C0", "80", "03", "02"),
    //             "bmp", list("0C", "03", "C0", "CF", "C3", "FC", "F3", "30", "3C", "3F")
    //         ),
    //         "Full", lex(
    //             "nrm", list("0F", "00", "41", "80", "29", "2A", "2B", "2E", "29", "2F"),
    //             "hlf", list("8F", "80", "CF", "C0", "AF", "A0"),
    //             "qtr", list("1F", "80"),
    //             "qsq", list("48", "44", "42", "41", "5C", "53", "5C", "53", "59"),
    //             "crc", list("EC", "DB", "CB", "3B")
    //         )
    //     ),
    //     "Diam", lex(
    //         "Full", lex(
    //             "dmd", list("E9", "E0", "EA", "F0")
    //         )
    //     ),
    //     "Tri",  lex(
    //         "Normal", lex(
    //             "up",  list("CF", "C0", "CA", "CE", "CD", "DF", "D0"),
    //             "dwn", list("41", "00", "19", "80"),
    //             "lft", list("89", "80", "99", "90", "A9", "A0"),
    //             "rgt", list("49", "40", "59", "50", "69", "60"),
    //             "spc", list("62", "E2", "A2", "22")
    //         )
    //     ),
    //     "Circ", lex(
    //         "Normal", lex(
    //             "crc", list("C0", "80", "A0"),
    //             "dtf", list("D4", "8D"),
    //             "pio", list("E8", "E4", "E2", "E1"),
    //             "pif", list("84", "83", "8C", "86", "89", "87", "8F"),
    //             "spc", list("8A")
    //         ),
    //         "Part", lex(
    //             "hlf", list("9C", "93")
    //         )
    //     ),
    //     "Grad", lex(
    //         "Rect", lex(
    //             "box", list("88", "AA", "FF")
    //         )
    //     )
    // )
).

// Contains dims and styles pointers needed to build basic shapes
global Shapes to lexicon(
    "Box", lex(
        "Base", lex(
            "Closed", lex(
                // "Pos", list(0, 0, Terminal:Width - 2, Terminal:Height - 4),  // Position: x0, y0, x1, y1 (the locations of the 4 corners)
                "Style",  "Normal",  // Name of style to get from __styles
                "Border", list(),
                "Rows",   list(),     // Rows: list(rowDat)
                "Cols",   list()     // Cols: list(colDat)
            ),
            "Open", lex(
                // "Pos", list(0, 0, Terminal:Width - 2, Terminal:Height - 4),  // Position: x0, y0, x1, y1 (the locations of the 4 corners)
                "Style", "Normal",  // Name of style to get from __styles
                "Rows", list(list()),     // Rows: list(rowDat)
                "Cols", list(list())     // Cols: list(colDat)
            )
        ),
        "Header", lex(
            // "Pos", list(0, 1, Terminal:Width - 2, 12),
            "Style", "Double",
            "Rows", list(),
            "Cols", list()
        )
    )
).

global UniFonts to lexicon(
    "0000", 65281, // ！
    "0000", 65282, // ＂
    "0000", 65283, // ＃
    "0000", 65284, // ＄
    "0000", 65285, // ％
    "0000", 65286, // ＆
    "0000", 65287, // ＇
    "0000", 65288, // （
    "0000", 65289, // ）
    "0000", 65290, // ＊
    "0000", 65291, // ＋
    "0000", 65292, // ，
    "0000", 65293, // －
    "0000", 65294, // ．
    "0000", 65295, // ／
    "0000", 65296, // ０
    "0000", 65297, // １
    "0000", 65298, // ２
    "0000", 65299, // ３
    "0000", 65300, // ４
    "0000", 65301, // ５
    "0000", 65302, // ６
    "0000", 65303, // ７
    "0000", 65304, // ８
    "0000", 65305, // ９
    "0000", 65306, // ：
    "0000", 65307, // ；
    "0000", 65308, // ＜
    "0000", 65309, // ＝
    "0000", 65310, // ＞
    "0000", 65311, // ？
    "0000", 65312, // ＠
    "0000", 65313, // Ａ
    "0000", 65314, // Ｂ
    "0000", 65315, // Ｃ
    "0000", 65316, // Ｄ
    "0000", 65317, // Ｅ
    "0000", 65318, // Ｆ
    "0000", 65319, // Ｇ
    "0000", 65320, // Ｈ
    "0000", 65321, // Ｉ
    "0000", 65322, // Ｊ
    "0000", 65323, // Ｋ
    "0000", 65324, // Ｌ
    "0000", 65325, // Ｍ
    "0000", 65326, // Ｎ
    "0000", 65327, // Ｏ
    "0000", 65328, // Ｐ
    "0000", 65329, // Ｑ
    "0000", 65330, // Ｒ
    "0000", 65331, // Ｓ
    "0000", 65332, // Ｔ
    "0000", 65333, // Ｕ
    "0000", 65334, // Ｖ
    "0000", 65335, // Ｗ
    "0000", 65336, // Ｘ
    "0000", 65337, // Ｙ
    "0000", 65338, // Ｚ
    "0000", 65339, // ［
    "0000", 65340, // ＼
    "0000", 65341, // ］
    "0000", 65342, // ＾
    "0000", 65343, // ＿
    "0000", 65344, // ｀
    "0000", 65345, // ａ
    "0000", 65346, // ｂ
    "0000", 65347, // ｃ
    "0000", 65348, // ｄ
    "0000", 65349, // ｅ
    "0000", 65350, // ｆ
    "0000", 65351, // ｇ
    "0000", 65352, // ｈ
    "0000", 65353, // ｉ
    "0000", 65354, // ｊ
    "0000", 65355, // ｋ
    "0000", 65356, // ｌ
    "0000", 65357, // ｍ
    "0000", 65358, // ｎ
    "0000", 65359, // ｏ
    "0000", 65360, // ｐ
    "0000", 65361, // ｑ
    "0000", 65362, // ｒ
    "0000", 65363, // ｓ
    "0000", 65364, // ｔ
    "0000", 65365, // ｕ
    "0000", 65366, // ｖ
    "0000", 65367, // ｗ
    "0000", 65368, // ｘ
    "0000", 65369, // ｙ
    "0000", 65370, // ｚ
    "0000", 65371, // ｛
    "0000", 65372, // ｜
    "0000", 65373, // ｝
    "0000", 65374  // ～
).
// #endregion

// Trying out a buffer object to hold messages pushed during the loop for later rendering
global MsgCon is lexicon(
    "TotalSlots", 3,
    "SlotsUsed", 0,
    "SlotsRem", 3,
    "LastUpdate", Time:Seconds,
    "0", lex(
        "Pri", 0,
        "ts", Time:Seconds,
        "exp", Time:Seconds + 5,
        "_", ""
    ),
    "1", lex(
        "Pri", 0,
        "ts", Time:Seconds,
        "exp", Time:Seconds + 5,
        "_", ""
    ),
    "2", lex(
        "Pri", 0,
        "ts", Time:Seconds,
        "exp", Time:Seconds + 5,
        "_", ""
    ),
    "BakedStr", lex(
        "Pre", list(
            "[INF]", // 0: Informational: Non-critical information or updates 
            "[MSG]", // 1: Message: Important information or updates
            "[WRN]", // 2: Warning: Non-fatal error, will continue or recover without intervention. Associated with a Master Warning alarm (__errlvl == 2). 
            "[CTN]", // 3: Caution: Non-fatal error, will continue or recover but may drop non-critical functions. Associated with a Master Caution alarm (__errlvl == 3)
            "[ERR]", // 4: Error: Non-fatal error but terminal - program cannot proceed and will exit. Associated with a Master Error Alarm (__errlvl == 4)
            "[EXC]"  // 5: Exception: Fatal error, and program will not be able to gracefully exit. Associated with a Master Exception alarm (__errlvl < 0)
        )
    )
).


// #include "0:/env/global/_init.ks"
// Contains mapped term field delegates used to refresh UI
global FieldDelegates to lexicon(
    "Head", lex(
        "Ver",  { parameter _pad. return ("{0," + _pad + "}"):Format(__ver). },
        "User", { parameter _pad. return ("{0," + _pad + "}"):Format(__user). }
    ),
    "Info", lex(
        "State", lex(
            "Prog", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Program). },
            "Rnmd", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Runmode). }
        ),
        "Ship", lex(
            "Name", { parameter _pad. return ("{0," + _pad + "}"):Format(Ship:Name). }
        ),
        "Msg", lex(
            "Con", lex(
                "0", { parameter _pad. if MsgCon["0"]:_:Length > 0 { return ("{0," + _pad + "}"):Format(MsgCon:BakedStr:Pre[MsgCon["0"]:Pri] + " " + MsgCon["0"]:_). } else { return ("{0," + _pad + "}"):Format(" ").} },
                "1", { parameter _pad. if MsgCon["1"]:_:Length > 0 { return ("{0," + _pad + "}"):Format(MsgCon:BakedStr:Pre[MsgCon["1"]:Pri] + " " + MsgCon["1"]:_). } else { return ("{0," + _pad + "}"):Format(" ").} },
                "2", { parameter _pad. if MsgCon["2"]:_:Length > 0 { return ("{0," + _pad + "}"):Format(MsgCon:BakedStr:Pre[MsgCon["2"]:Pri] + " " + MsgCon["2"]:_). } else { return ("{0," + _pad + "}"):Format(" ").} }
            )
        )
    ),
    "Core", lex(
        "Panel", lex(
            "Asc", lex(
                "Tel", lex(
                    "Title", { parameter _pad. return ("{0," + _pad + "}"):Format("ASCENT TELEMETRY"). }
                ),
                "Alt", lex(
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("ALTITUDE"). },
                    "Asl", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Altitude)).},
                    "Agl", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Altitude - Ship:Geoposition:TerrainHeight)).},
                    "Rad", { parameter _pad. return ("{0," + _pad + "}"):Format(Round((Ship:Position - Body:Position):Mag)).}
                ),
                "Velo", lex(
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("VELOCITY"). },
                    "Srf", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Velocity:Surface:Mag, 1)).},
                    "Obt", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Velocity:Orbit:Mag, 1)).  },
                    "GS",  { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Groundspeed, 1)).         },
                    "VS",  { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Verticalspeed, 1)).       }
                ),
                "Apo", lex(
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("APOAPSIS"). },
                    "Cur", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Apoapsis, 1)). },
                    "Eta", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(ETA:Apoapsis, 2)). }
                ),
                "Per", lex(
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("PERIAPSIS"). },
                    "Cur", {parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Periapsis, 1)). },
                    "Eta", {parameter _pad. return ("{0," + _pad + "}"):Format(Round(ETA:Periapsis, 2)). }
                ),
                "Inc", lex(
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("INCLINATION"). },
                    "Cur", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Orbit:Inclination, 2)). },
                    "Lan", { parameter _pad. return ("{0," + _pad + "}"):Format(Round(Ship:Orbit:LongitudeOfAscendingNode, 2)). }
                ),
                "Prm", lex(
                    "Title", { parameter _pad. return ("{0," + _pad + "}"):Format("PARAMETERS"). },
                    "Label", { parameter _pad. return ("{0," + _pad + "}"):Format("TARGETS"). },
                    "TgtInc", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Mission:CurScope:Param:Inc). },
                    "TgtAlt", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Mission:CurScope:Param:Alt). },
                    "TgtApo", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Mission:CurScope:Param:Apo). },
                    "StgLim", { parameter _pad. return ("{0," + _pad + "}"):Format(g_Mission:CurScope:StgLim). }
                )
            )
        )
    ),
    "Foot", lex(

    )
).