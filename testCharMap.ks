@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/kslib/lib_loader.ks").
RunOncePath("0:/env/types/_init.ks").
RunOncePath("0:/env/global/_init.ks").
RunOncePath("0:/lib/util.ks").
RunOncePath("0:/lib/control.ks").
RunOncePath("0:/lib/module.ks").
RunOncePath("0:/lib/string.ks").
RunOncePath("0:/lib/term.ks").

// Declare Variables


// Parse Params
// if _params:length > 0 
// {
//   set _minRange to _params[0].
//   if _params:length > 1 set _maxRange to _params[1].
//   if _params:length > 2 set _vOffset to _params[2].
// }

// local headerCharMap to list(
    // list("133",1, "10F",17,   "12F", 1, "10F",34, "12F", 1, "10F",17, "13C", 1),
    // list("1F0",1, "000", 1, "MCM Version    ", 1, "000", 1, "1A0", 1, "000",13, "CREISoft",1, "000",13, "1A0",1, "000",1, "   Licensed To:",1, "000",1, "1F0",1),
    // list("1F2",1, "10A", 8,   "12A", 1, "10A", 8, "388", 1, "322", 1, "10A", 3, "32A",1, "3A2",1, "10A",6, "32A",1, "80F",8, "3A2",1, "10A",6, "32A",1, "3A2",1, "10A",3, "328",1, "382",1, "10A",8, "12A",1, "10A",8, "1F8", 1),
    // list("1F0",1, "000", 1, "0.0.01",1, "000", 1, "1A0", 1, "000", 8, "32A", 1, "80F",2, "3A2",1, "32A",1, "000",2, "3A2",1, "000",4, "81F",1, "000",2, "32A",1, "80F",5, "3A2",1, "32A",1, "000",5, "32A",1, "000",2, "3A2",1, "32A",1, "80F",2, "3A2",1, "000",8, "1A0",1, "000",1, " KUSA ",1, "000",1, "1F0",1),
    // list("1F2",1, "10A", 1,   "12A", 1, "10A", 1, "12A", 1, "10A", 4, "388", 1, "000",7, "32A",1, "800",1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",3, "81F",1, "000",2, "3A2",1, "800",5, "32A",1, "3A2",1, "000",4, "32A",1, "800", 1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",7, "382",1, "10A",4, "12A", 1, "10A", 1, "12A", 1, "10A", 1, "1F8",1),
    // list("1F2",1, "12A", 1,   "1AA", 1, "10A", 1, "388", 1, "000",11, "81F", 1, "32A",1, "000",1, "382",1, "10A",6, "3A2",1, "810",1, "10A",3, "3A2",1, "800",8, "32A",1, "10A",3, "81F",1, "32A",1, "10A",6, "388",1, "000",1, "3A2",1, "810",1, "000",11, "382",1, "10A",1, "1AA", 1, "12A",1, "1F8",1),
    // list("1F0",1, "000", 1,   "1A0", 1, "000", 9, "030", 1, "000", 2, "62C", 1, "628",1, "632",2, "628",1, "62E",1, "62D",1, "000",8, "002",1, "000",8, "62C",1, "620",1, "62D",1, "620",1, "626",1, "624",1, "631",1, "04A",1, "000",1, "030",1, "000",9, "1A0",1, "000",1, "1F0",1),
    // list("1F2",1, "18A", 1,   "1A8", 1, "000",25, "030", 1, "003", 2, "002", 1, "622",1, "62E",1, "62D",1, "633",1, "631",1, "62E",1, "62B",1, "002",2, "003",1, "030",1, "000", 24, "1A2",1, "18A",1, "1F8",1)

//     list("133",1, "10F",17, "12F", 1, "10F",42, "12F",1, "10F",17, "13C",1),
//     list("1F0",1, "000", 1, "MCM Version    ",1, "000",1, "1A0",1, "000",17, "CREISoft",1, "000",17, "1A0",1, "000",1, "   Licensed To:",1, "000",1, "1F0",1),
//     list("1F2",1, "10A", 8, "12A", 1, "10A",8, "388",1, "000",4, "322",1, "10A",3, "32A",1, "3A2",1, "10A",6, "32A",1, "80F",8, "3A2",1, "10A",6, "32A",1, "3A2",1, "10A",3, "328",1, "000",4, "382",1, "10A",8, "12A",1, "10A",8, "1F8",1),
//     list("1F0",1, "000", 1, "0.0.01",1, "000",1, "1A0",1, "000",12, "32A",1, "80F",2, "3A2",1, "32A",1, "000",2, "3A2",1, "000",4, "81F",1, "000",2, "32A",1, "80F",5, "3A2",1, "32A",1, "000",5, "32A",1, "000",2, "3A2",1, "32A",1, "80F",2, "3A2",1, "000",12, "1A0",1, "000",1, " KUSA ",1, "000",1, "1F0",1),
//     list("1F2",1, "12A", 2, "10A", 1, "12A", 1, "10A", 4, "388", 1, "000", 11, "32A",1, "000",1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "000",1, "3A2",1, "000",3, "81F",1, "000",1, "81F",1, "000",12, "32A",1, "000", 1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "000",1, "3A2",1, "000",11, "382",1, "10A",4, "12A", 1, "10A", 1, "12A", 2, "1F8",1),
//     list("1F0",1, "000", 1, "10A", 1, "000", 1, "10A", 1, "000",15, "32A", 1, "000",1, "32A",1, "10A", 1, "000",5, "3A2",1, "800",1, "810",1, "000",2, "81F",1, "000",2, "3A2",1, "800",5, "32A",1, "3A2",1, "000",3, "81F",1, "800",1, "32A",1, "000",5, "3A2",1, "000",1, "3A2",1, "000",15, "1A0",1, "000", 1, "1A0", 1, "000", 1, "1F0",1),

//     list("1F2",1, "10A", 1, "12A", 1, "10A", 1, "12A", 1, "10A", 4, "388", 1, "000",11, "32A",1, "800",1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",3, "81F",1, "000",2, "3A2",1, "800",5, "32A",1, "3A2",1, "000",4, "32A",1, "800", 1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",11, "382",1, "10A",4, "12A", 1, "10A", 1, "12A", 1, "10A", 1, "1F8",1),
//     list("1F0",1, "12A", 1, "1AA", 1, "10A", 1, "388", 1, "000",15, "81F", 1, "32A",1, "000",1, "382",1, "10A",6, "3A2",1, "810",1, "10A",3, "3A2",1, "800",8, "32A",1, "10A",3, "81F",1, "32A",1, "10A",6, "388",1, "000",1, "3A2",1, "810",1, "000",15, "382",1, "10A",1, "1AA", 1, "12A",1, "1F8",1),
//     list("1F2",1, "000", 1, "1A0", 1, "000",74, "1A0",1, "000",1, "1F0",1),
//     list("1F0",1, "000", 1, "1A0", 1, "000",13, "B06", 1, "000", 2, "62C", 1, "628",1, "632",2, "628",1, "62E",1, "62D",1, "000",8, "003",3, "000",8, "62C",1, "620",1, "62D",1, "620",1, "626",1, "624",1, "631",1, "04A",1, "000",1, "B06",1, "000",12, "002",1, "1A0",1, "000",1, "1F0",1),
//     list("1F2",1, "18A", 1, "1A8", 1, "000",28, "003", 1, "B07", 1, "003", 1, "001", 1, "622", 1, "62E",1, "62D",1, "633",1, "631",1, "62E",1, "62B",1, "001",1, "003",1, "B07",1, "000",27, "002",1, "1A2",1, "18A",1, "1F8",1)

    // Full Monty
    
// ).

// local getHexChar to HexChar:Get_@.

// local vOffset to 2.

// local ContiguousCharSegments to 0.
// local TotalCharacterCount to 0.

// for _line in headerCharMap {

//     set ContiguousCharSegments to ContiguousCharSegments + (_line:Length / 2).

//     from { local _i to 1. } until _i >= _line:length step { set _i to _i + 2.  } do {

//         set TotalCharacterCount to TotalCharacterCount + _line[_i].
//     }
// }

// local frameBuff is lexicon().

// local _line to vOffset.

// local progressLex to lexicon(
//     "Line",    list(0, headerCharMap:Length - 1, list(2, 16)), // Current Line Value, Max Line Value
//     "Segment", list(0, ContiguousCharSegments,   list(2, 17)),
//     "Char",    list(0, TotalCharacterCount,      list(2, 18)),
//     "Template", "{0,8}:  {1,5:P1}%  ( {2,3:d3} | {3,-3:d3} ) "
// ).

// print  "Progress: Pct% ( Cur | Max ) " at (0, progressLex:Line[2][1] - 2).

// for strLine in headerCharMap {

//     local prgType to "Line".
//     local progressSet to progressLex[prgType].
//     set progressSet[0] to progressSet[0] + 1.
//     print progressLex:Template:Format(prgType, Round(100 * (Max(1, progressSet[0]) / progressSet[1]), 2), progressSet[0], progressSet[1]) at (0, progressSet[2][1]).

//     local str to "".

//     from { local _iMoniker to 0. local _iCount to 1.} until (_iMoniker >= strLine:Length or _iCount >= strLine:Length) step { set _iMoniker to _iMoniker + 2. set _iCount to _iCount + 2. } do {

//         // print _iMoniker.
//         // print _iCount.

//         set   prgType to "Segment".
//         local segProgSet to progressLex[prgType].
//         set   segProgSet[0] to segProgSet[0] + 1.
//         print progressLex:Template:Format(prgType, Round(100 * (Max(1, segProgSet[0]) / segProgSet[1]), 2), segProgSet[0], segProgSet[1]) at (0, segProgSet[2][1]).

//         local charCount   to strLine[_iCount].
//         local charMoniker to strLine[_iMoniker].
//         local charOut     to "".

//         if charMoniker:MatchesPattern("([0-9a-fA-F]){3}") {

//             set charOut to str_gen(getHexChar(charMoniker), charCount).

//         } else {

//             if charCount = 1 {

//                 set charOut to charMoniker.
            
//             } else {

//                 set charOut to str_gen(charMoniker, charCount).

//             }
//         }

//         set str to str + charOut.

//         set prgType to "Char".
//         local chrProgSet to progressLex[prgType].
//         set   chrProgSet[0] to chrProgSet[0] + charCount.
//         print progressLex:Template:Format(prgType, Round(100 * (Max(1, chrProgSet[0]) / chrProgSet[1])), chrProgSet[0], chrProgSet[1]) at (0, chrProgSet[2][1]).
//     }

//     set frameBuff[_line] to str.
//     set _line to _line + 1.
// }

// Wait 0.5.
// ClearScreen.

// for _vOffset in frameBuff:Keys
// {
//     print frameBuff[_vOffset] at (0, _vOffset).
// }

// list("133",1, "10F",17, "12F", 1, "10F",34, "12F",1, "10F",17, "13C",1),
// list("1F0",1, "000", 1, "MCM Version    ",1, "000",1, "1A0",1, "000",13, "CREISoft",1, "000",13, "1A0",1, "000",1, "   Licensed To:",1, "000",1, "1F0",1),
// list("1F2",1, "10A", 8, "12A", 1, "10A",8, "388",1, "322",1, "10A",3, "32A",1, "3A2",1, "10A",6, "32A",1, "80F",8, "3A2",1, "10A",6, "32A",1, "3A2",1, "10A",3, "328",1, "382",1, "10A",8, "12A",1, "10A",8, "1F8",1),
// list("1F0",1, "000", 1, "0.0.01",1, "000",1, "1A0",1, "000",8, "32A",1, "80F",2, "3A2",1, "32A",1, "000",2, "3A2",1, "000",4, "81F",1, "000",2, "32A",1, "80F",5, "3A2",1, "32A",1, "000",5, "32A",1, "000",2, "3A2",1, "32A",1, "80F",2, "3A2",1, "000",8, "1A0",1, "000",1, " KUSA ",1, "000",1, "1F0",1),
// list("1F2",1, "10A", 1, "12A", 1, "10A", 1, "12A", 1, "10A", 4, "388", 1, "000", 7, "32A",1, "800",1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",3, "81F",1, "000",2, "3A2",1, "800",5, "32A",1, "3A2",1, "000",4, "32A",1, "800", 1, "32A",1, "3A2",1, "800",2, "32A",1, "3A2",1, "800",1, "3A2",1, "000",7, "382",1, "10A",4, "12A", 1, "10A", 1, "12A", 1, "10A", 1, "1F8",1),
// list("1F2",1, "12A", 1, "1AA", 1, "10A", 1, "388", 1, "000",11, "81F", 1, "32A",1, "000",1, "382",1, "10A",6, "3A2",1, "810",1, "10A",3, "3A2",1, "800",8, "32A",1, "10A",3, "81F",1, "32A",1, "10A",6, "388",1, "000",1, "3A2",1, "810",1, "000",11, "382",1, "10A",1, "1AA", 1, "12A",1, "1F8",1),
// list("1F0",1, "000", 1, "1A0", 1, "000", 9, "B06", 1, "000", 1, "000", 1, "62C", 1, "628",1, "632",2, "628",1, "62E",1, "62D",1, "000",8, "003",3, "000",8, "62C",1, "620",1, "62D",1, "620",1, "626",1, "624",1, "631",1, "04A",1, "000",1, "B06",1, "000",9, "1A0",1, "000",1, "1F0",1),
// list("1F2",1, "18A", 1, "1A8", 1, "000",24, "003", 1, "B07", 1, "003", 1, "001", 1, "622", 1, "62E",1, "62D",1, "633",1, "631",1, "62E",1, "62B",1, "001",1, "003",1, "B07",1, "000", 24, "1A2",1, "18A",1, "1F8",1)