// #include "0:/boot/_bl.ks"
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/globals").

writeJson(list(ship:name), "vessel.json").

// Initialize vars
local archivePath to "".
local setupScript to "".
local planList to list().

if setupScript = ""
{
     until planList:length > 0
     {
          set planList to GetPlanPaths().
     }
     set setupScript to planList[0].
     set archivePath to planList[1].
}
runPath(setupScript).
writeJson(mp, archivePath).

local function GetPlanPaths
{
     local backupPath to path("0:/_plan/" + plan + "/mp_" + missionName + ".json").
     local setupPath to path("0:/_plan/" + plan + "/setup.ks").
     if branch <> "" 
     {
          if branch:toNumber(-1) = -1 set setupPath to path("0:/_plan/" + plan + "/setup_" + branch + ".ks").
     }
     
     if exists(setupPath) 
     {
          return list(setupPath, backupPath).
     }
     else
     {
          ClearScreen.
          InitTerm().
          print "No core tag on CPU!" at (0, 0).
          wait 1.
          print "Please input a core tag. Press 'Enter' to submit." at (0, 2).
          set core:tag to GetUserInput(core:part:name + " Tag").
          
          set planTags to ParseTag(core).
          set plan to planTags[0].
          set branch to choose planTags[1] if planTags:length > 1 else "".
     }
}

global function GetUserInput
{
     parameter prompt is "Input".

     local str to "".
     until false
     {
          set g_termChar to GetInputChar().
          if g_termChar = Terminal:Input:Enter
          {
               break.
          }
          else if g_termChar = Terminal:Input:Backspace
          {
               if str:length > 0 set str to str:remove(str:length - 1, 1).
          }
          else
          {
               set str to str + g_termChar.
               set g_termChar to "".
          }
          print prompt + ": [" + str + "]                       " at (0, 3).
     }
     return str.
}

local function ParseTag
{
    parameter c.

    local fragList to list().
    local pipeSplit to c:tag:split("|").
    for word in pipeSplit
    {
        local colonSplit to word:split(":").
        for frag in colonSplit
        {
            fragList:add(frag).
        }
    }
    return fragList.
}