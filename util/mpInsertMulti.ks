@lazyGlobal off.
clearScreen.
parameter insertAt  is 0,
          resetMP   is false,
          fileList  is Volume("Archive"):files.

runOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

local flags to initFlags(list("next")).
local newPlan to list().

if fileList:IsType("lexicon") 
{
    set fileList to choose fileList["main"]:lex if fileList:keys:contains("main") else fileList.
}

from { local scriptIdx to 0.} until flags["end"] step { set scriptIdx to scriptIdx + 1.} do
{
    local selectedItem to PromptFileSelect("Choose item", fileList).
    if selectedItem:IsFile
    {
        set selectedItem to Path(selectedItem):tostring:split("main/")[1]:replace(".ks",""):replace(".ksm","").
    }
    newPlan:add(selectedItem).
    ResetDisp().
    OutMsg("Item selected: " + selectedItem).
    
    OutInfo("Parameters").
    local paramList to list().
    until flags["end"] 
    {
        ResetDisp().
        

        getChoice().
        if flags["next"] or flags["delete"]
        {
            local param to "".
            cr().
            if flags["next"]
            {
                set param to PromptTextEntry("Enter parameter").
                if param:length > 0
                {
                    if param:toNumber(-1234567890) = -1234567890
                    {
                        set param to param:toNumber().
                    }
                    paramList:add(param).
                }
                set param to "".
                set flags["next"] to false.
            }
            else
            {
                if paramList:length > 0 
                {
                    paramList:remove(paramList:length - 1).
                }
                set flags["delete"] to false.
            }
        }
    }
    // Print out the params here
    from { local i to 0.} until i >= paramList:length step { set i to i + 1.} do 
    {
        print ("{0, -1}  {1}"):format(i, paramList[i]) at (2, cr()).
    }
    newPlan:add(paramList).

    ResetDisp().
    DispMissionPlan(newPlan, "Pending plan additions [start index: " + insertAt + "]").

    OutMsg("Add another script?").
    
    getChoice().
    if flags["end"]
    {
        break.
    }
    else if flags["delete"]
    {
        newPlan:remove(scriptIdx + 1).  // Remove the params
        newPlan:remove(scriptIdx).      // Remove the script
        set scriptIdx to scriptIdx - 1.
    }
}

local mp to choose readJson("mp.json") if exists("mp.json") else list().
if resetMP set mp to list().
from { local i to newPlan:length - 1.} until i <= 0 step { set i to i - 2.} do
{
    mp:insert(insertAt, newPlan[i]).
}
writeJson(mp, "mp.json").
OutMsg("mpInsertMulti complete").
OutInfo().
OutInfo2().

DispMissionPlan(mp, "Updated plan:").

// End

// Local functions
local function getChoice
{
    OutInfo("[Next <Enter> | Done <End> | Back <Delete / Backspace>]").
    
    terminal:input:clear.
    set flags to initFlags().
    local choiceMade to false.
    until choiceMade
    {
        GetInputChar().

        if g_termChar = Terminal:Input:Enter
        {
            set choiceMade to true.
            set flags["next"] to true.
            //set flags["done"] to true.
        }
        else if g_termChar = Terminal:Input:EndCursor
        {
            set choiceMade to true.
            set flags["end"] to true.
        }
        else if g_termChar = Terminal:Input:DeleteRight or g_termChar = Terminal:Input:Backspace
        {
            set choiceMade to true.
            set flags["delete"] to true.
        }
    }
    wait 1.
    return 0.
}

local function initFlags
{
    parameter presetFlags to list().

    local flagLex to lex(
        "next", false
        ,"done", false
        ,"delete", false
        ,"end", false
    ).

    for f in presetFlags
    {
        if f = "next"           set flagLex[f] to true.
        else if f = "done"      set flagLex[f] to true.
        else if f = "delete"    set flagLex[f] to true.
        else if f = "end"       set flagLex[f] to true.
    }

    return flagLex.
}