@lazyGlobal off.
clearScreen.
parameter insertAt  is 0,
          resetMP   is false,
          fileList  is Volume("Archive"):files.

runOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

local deleteFlag to false.
local endFlag to false.
local nextFlag to false.
local doneFlag to false.
local flags to initFlags(list("next")).

local newPlan to list().

if fileList:IsType("lexicon") 
{
    set fileList to choose fileList["main"]:lex if fileList:keys:contains("main") else fileList.
}

from { local scriptIdx to 0.} until endFlag step { set scriptIdx to scriptIdx + 1.} do
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

    until endFlag
    {
        getChoice().
        if nextFlag or deleteFlag
        {
            local param to "".
            cr().
            if nextFlag
            {
                set param to PromptTextEntry("Enter parameter").
                if param:length > 0
                {
                    if param:toNumber(-9999) = -9999
                    {
                        set param to param:toNumber().
                    }
                    paramList:add(param).
                }
                set param to "".
                set nextFlag to false.
            }
            else
            {
                if paramList:length > 0 
                {
                    paramList:remove(paramList:length - 1).
                }
                set deleteFlag to false.
            }
        }
        ResetDisp().
        // Print out the params here
        from { local i to 0.} until i >= paramList:length step { set i to i + 1.} do 
        {
            print ("{0, -1}  {1}"):format(i, paramList[i]) at (2, cr()).
        }
    }
    set endFlag to false.

    newPlan:add(paramList).

    ResetDisp().
    DispMissionPlan(newPlan, "Pending plan additions [start index: " + insertAt + "]").

    OutMsg("Add another script?").
    
    getChoice().
    if endFlag
    {
        break.
    }
    else if deleteFlag
    {
        newPlan:remove(scriptIdx + 1).  // Remove the params
        newPlan:remove(scriptIdx).      // Remove the script
        set scriptIdx to scriptIdx - 1.
    }
}

local mpUpdate to choose readJson("mp.json") if exists("mp.json") else list().
if resetMP
{
    set mpUpdate to list().
    set insertAt to 0.
}

from { local i to newPlan:length - 1.} until i <= 0 step { set i to i - 1.} do
{
    mpUpdate:insert(insertAt, newPlan[i]).
}

DispList(mpUpdate).

writeJson(mpUpdate, "mp.json").
OutMsg("mpInsertMulti complete").
OutInfo().
OutInfo2().

DispMissionPlan(mpUpdate, "Updated plan:").

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
            set nextFlag to true.
            //set flags["done"] to true.
        }
        else if g_termChar = Terminal:Input:EndCursor
        {
            set choiceMade to true.
            set endFlag to true.
        }
        else if g_termChar = Terminal:Input:DeleteRight or g_termChar = Terminal:Input:Backspace
        {
            set choiceMade to true.
            set deleteFlag to true.
        }
    }
    wait 1.
    return 0.
}

local function initFlags
{
    parameter presetFlags to list().

    set deleteFlag to false.
    set doneFlag to false.
    set endFlag to false.
    set nextFlag to false.

    // local flagLex to lex(
    //     "delete",   false
    //     ,"done",    false
    //     ,"end",     false
    //     ,"next",    false
    // ).

    for f in presetFlags
    {
        if f = "next"
        {
            // set flagLex[f] to true.
            set nextFlag to true.
        }
        else if f = "done"
        {
            // set flagLex[f] to true.
            set doneFlag to true.
        }
        else if f = "delete"
        {
            // set flagLex[f] to true.
            set deleteFlag to true.
        }
        else if f = "end"
        {
            // set flagLex[f] to true.
            set endFlag to true.
        }
    }

    return list(deleteFlag, doneFlag, endFlag, nextFlag).

    // return flagLex.
}