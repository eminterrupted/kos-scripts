@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local srcRes to "".
local tgtRes to "".
local xfrAmt to 0.
local finalPct to 0.

local srcElement to "".
local tgtElement to "".
local tgtRoom to 0.
local tgtValid to false.

// Parse Params
if params:length > 0 
{
  set srcElement to params[0].
  if params:length > 1 set tgtElement to params[1].
  if params:length > 2 set srcRes to params[2].
  if params:length > 3 set finalPct to params[3].
}

local elList to ship:elements.

if srcElement = "" 
{
    set srcElement to PromptItemSelect("srcElement", "Choose Source Element", elList).
    //elList:remove(srcElement).
}
if tgtElement = "" set tgtElement to PromptItemSelect("tgtElement", "Choose Target Element", elList).
if srcRes = "" set srcRes to PromptItemSelect("res", "Choose Resource", srcElement:resources).
if finalPct = 0 set finalPct to PromptCursorSelect("resPct", Range(0, 100, 5), 10).
set xfrAmt to min(srcRes:amount, (1 - (finalPct / 100)) * srcRes:capacity).

// Validate the target can accept the resource
for _r in tgtElement:resources
{
    if _r:name = srcRes:name 
    {
        set tgtValid to true.
        set tgtRes to _r.
        break.
    }
}
set xfrAmt to round(Min(xfrAmt, tgtRes:capacity - tgtRes:Amount), 3).
OutMsg("Trasfer Amount: " + xfrAmt).
if tgtValid
{
    clrDisp().
    DispResTransfer(srcElement, tgtElement, srcRes, xfrAmt).
    Pause(1).
    Main().
}
else
{
    OutMsg("ERROR: Selected target element can not store resource!").
    OutInfo("Element: " + tgtElement).
    OutInfo2("Resource: " + srcRes).
}

// Yolo
local function Main
{
    local xfr to transfer(srcRes:name, srcElement:Parts, tgtElement:Parts, xfrAmt).
    OutMsg("Transfer in progress").
    OutInfo2("Press End to terminate transfer").
    local doneFlag to false.
    local strtAmt to srcRes:amount.
    local tgtAmt to strtAmt - xfrAmt.
    until doneFlag
    {
        set g_termChar to GetInputChar().
        if g_termChar = Terminal:Input:Enter
        {
            OutInfo("Press Delete to stop transfer").
            set xfr:active to true.
        }
        else if g_termChar = Terminal:Input:DeleteRight
        {
            OutInfo("Press Enter to begin transfer").
        }
        else if g_termChar = Terminal:Input:endcursor
        {
            OutInfo("Ending Transfer").
            set xfr:active to false.
            set doneFlag to true.
        }

        if tgtRes:Amount >= (tgtRes:Capacity * 0.9995) or srcRes:Amount <= (tgtAmt * 1.0005)
        {
            OutInfo("Transfer complete!").
            set xfr:active to false.
            set doneFlag to true.
        }
        wait 0.1.
        DispResTransfer(srcElement, tgtElement, srcRes, xfrAmt).
    }
    OutMsg("Transfer complete!").
    OutInfo().
}