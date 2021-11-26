runOncePath("0:/lib/util").

local planPath to path("0:/_plan/" + plan + "/mp_" + missionName + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks"). 
set branchName to parseMissionName(ship:name, " ")["branch"].
    
set setupPath to choose path("0:/_plan/" + plan + "/" + branchName + "_setup.ks") if branchName <> "" else path("0:/_plan/" + plan + "/setup.ks").
print setupPath at (2, 25).
Breakpoint().
runPath(setupPath).
writeJson(mp, planPath).


local function parseMissionName
{
    parameter str, splitChar.
    
    local splitList to str:split(splitChar).
    local branchName to "".
    local coreName to "".
    
    local charList to list(" ", "-", ".").

    if splitList:length > 1 
    {
        set coreName to splitList[0].
        if splitList[1]:tonumber(-1) = -1 set branchName to splitList[1].
    }
    
    // local idx to 0.
    // for splStr in splitList
    // {
        // print "Loop start: idx[" + idx + "]".
        // for c in charList
        // {
            // local splStr_1 to splStr:split(c).
            // if idx = 0 and splStr_1:length = 1
            // {
                // if coreName = "" 
                // {
                    // set coreName to splStr_1[0].
                    // print "set core name  : " + coreName.
                // }
            // }
            // else if splStr_1:length > 1 
            // {

                // if idx = 0 
                // {
                    // if coreName = "" 
                    // {
                        // set coreName to splStr_1[0].
                        // print "set core name  : " + coreName.
                    // }
                    // if branchName = "" 
                    // {
                        // set branchName to splStr_1[1].
                        // print "set branch name: " + branchName.
                    // }
                // }

                // else if idx = 1
                // {
                    
                    // set branchName to splStr_1[0].
                    // print "set branch name: " + splStr_1[0].
                // }
            // }
        // }
        // print "Loop end: idx[" + idx + "]".
        // print " ".
        // set idx to idx + 1.
    // }

    return lex("branch", branchName, "core", coreName, "parts", splitList).
}