@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/launch").

parameter p0, p1 is 0.

PlaySFX(0).

// print "Testing BurnDurFunc".
// print "-------------------".
// print "input".
// print "dV: " + p0.
// print " ".
// print "-- CalcBurnDur --".
// local burnDur to CalcBurnDur(p0).
// print "output (s): " + burnDur:join(";").
// print " ".
// print "-- BurnStagesUsed --".
// local burnStg to BurnStagesUsed(p0).
// for k0 in burnStg:keys {
//     print k0.
//     for k1 in burnStg[k0]:keys
//     {
//         print k1 + ": " + burnStg[k0][k1].
//     }
// }


// print "FUNCTIONAL TEST SCRIPT    v0.000001a".
// print "====================================".

// local charList to list(" ", ".", "-", "_", ":").

// print "Mission name: " + p0.

// local str to p0.

// local strLex to lex().
// for c in charList
// {
//     print "-----------------------------------------------".
//     print "Parsing by char [" + c + "]".
//     print " ".
//     local strSplit to str:split(c).
//     print strSplit:length + " part(s)".
//     local partsStr to " ".
//     if strSplit:length > 1 
//     {
//         set strLex[c] to strSplit.
//         for spl in strSplit
//         {
//             for ch in charList
//             {
//                 local spl2 to spl:split(ch).
//                 if spl2:length > 1 
//                 {
//                     from { local idx to 0.} until idx > spl2:length - 1 step { set idx to idx + 1.} do 
//                     {
//                         set partsStr to partsStr + ch + "[" + spl2[idx] + "]".
//                     }
//                 }
//             }
//         }
//     }
//     else set partsStr to partsStr + " [" + strSplit[0] + "].".
//     set partsStr to "Parts         : " + partsStr:remove(0, 1).
//     print partsStr.
// }





// for char in list(" ", ".")
// {
//     print "-----------------------------------------------".
//     print "Parsing by char [" + char + "]".
//     print " ".
//     local parsedName to parseMissionName(p0, char).
//     print "Count of parts: " + parsedName["parts"]:length.
//     local str to "Parts         : ".
//     for strPart in parsedName["parts"]
//     {
//         set str to str + "[" + strPart + "].".
//     }
//     set str to str:remove(str:length - 1, 1).
//     print str. 
//     print "Core name     : " + parsedName["core"].
//     print "Branch name   : " + parsedName["branch"].
//     print "-----------------------------------------------".
//     print " ".
// }

// local function parseMissionName
// {
//     parameter str, splitChar.
    
//     local splitList to str:split(splitChar).
//     local branchName to "".
//     local coreName to "".
    
//     if splitList:length > 1 set branchName to splitList[1].
    
//     local idx to 0.
//     for splStr in splitList
//     {
//         print "Loop start: idx[" + idx + "]".
//         for c in charList
//         {
//             local splStr_1 to splStr:split(c).
//             if idx = 0 and splStr_1:length = 1
//             {
//                 if coreName = "" 
//                 {
//                     set coreName to splStr_1[0].
//                     print "set core name  : " + coreName.
//                 }
//             }
//             else if splStr_1:length > 1 
//             {

//                 if idx = 0 
//                 {
//                     if coreName = "" 
//                     {
//                         set coreName to splStr_1[0].
//                         print "set core name  : " + coreName.
//                     }
//                     if branchName = "" 
//                     {
//                         set branchName to splStr_1[1].
//                         print "set branch name: " + branchName.
//                     }
//                 }

//                 else if idx = 1
//                 {
                    
//                     set branchName to splStr_1[0].
//                     print "set branch name: " + splStr_1[0].
//                 }
//             }
//         }
//         print "Loop end: idx[" + idx + "]".
//         print " ".
//         set idx to idx + 1.
//     }

//     return lex("branch", branchName, "core", coreName, "parts", splitList).
// }