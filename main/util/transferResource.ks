@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name, false).

// Declare Variables
local amt to 0.
local amtType to "%".
local srcRes to "".
local tgtRes to "".
local xfrAmt to 0.

local resRatios to lex(
    "KO",           list(0.9, 1.1, 0.1)
    ,"HO",          list(1.5, 0.1, 0.1)
    ,"MO",          list(3.0, 1.0, 0.1)
    ,"MP",          list(0.025)
    ,"Snacks",      list(0.1)
    ,"Oxygen",      list(0.025)
    ,"Hydrogen",    list(0.05)
    ,"Soil",        list(0)
    ,"Argon",       list(0.05)
    ,"Xenon",       list(0.05)
    ,"Lithium",     list(0.05)
).

local srcElement to "".
local tgtElement to "".
local tgtValid to false.

// Parse Params
if params:length > 0 
{
  set srcElement to params[0].
  if params:length > 1 set tgtElement to params[1].
  if params:length > 2 set srcRes to parseResourceParam(params[2]).
  if params:length > 3 set amt to params[3].
  if params:length > 4 set amtType to params[4].
}

local elList to ship:elements.

// if srcElement = "" 
// {
//     print 1 / 0.
    //set srcElement to PromptItemSelect("srcElement", "Choose Source Element", elLi).
    //elList:remove(srcElement).
// }

if srcElement = "" 
{
    set srcElement to PromptItemSelect(elList, "Choose Source Element", true).
    if tgtElement = "" set tgtElement to PromptItemSelect(elList:remove(elList:indexOf(srcElement)), "Choose Target Element", true).
    
    if srcRes = "" set srcRes to PromptItemSelect(srcElement:resources, "Choose Resource", true, "srcRes", true).
    if tgtRes = "" set tgtRes to PromptItemSelect(tgtElement:resources, "Choose Target Resource", true, "tgtRes").
    if amt = 0 
    {
        set amt to PromptInput("Enter amount", true, "Amt", amtType, "Scalar", list(tgtRes:capacity - tgtRes:amount)).
        set amtType to PromptItemSelect(list("units", "% capacity"), "Amount type", true, "amtType").
    }

    set safeAmt to safeLex[srcRes:name].
    // Validate the target can accept the resource
    set tgtValid to false.
            
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
}

// Yolo
local function Main
{
    local xfr to transfer(srcRes:name, srcElement, tgtElement, xfrAmt).
    OutMsg("Transfer in progress").
    OutInfo2("Press End to terminate transfer").
    local doneFlag to false.
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
        DispResTransfer(srcElement, tgtElement, srcRes, min(xfrAmt, srcRes:amount * 0.90)).
    }
    OutMsg("Transfer complete!").
    OutInfo().
}


// Functions


local function DoTransfer
{
    parameter _src, 
              _tgt,
              _srcRes,
              _amt. 
    
    local _tgtRes to _tgt:resources[_tgt:resources:indexOf(_srcRes:name)].
    local _srcBaseline to _srcRes:amount. 
    local _xfr to transfer(_srcRes:name, _src, _tgt, _amt).
    
    set _xfr:active to true. 
    OutMsg("Transfer initiated").
    OutInfo("Resource: " + _srcRes:name).
    until _xfr:status <> "Transferring"
    {
        set _srcRes to _src:resources[_src:resources:indexOf(_srcRes:name)].
        set _tgtRes to _tgt:resources[_tgt:resources:indexOf(_srcRes:name)].

        print "Progress: {0}/{1} ({2}%)":format(abs(round(_srcBaseline - _srcRes:amount, 2)), _amt, round((_srcRes:amount / _amt) * 100)) at (2, 24).
        print "SrcResource: {0}   {1}/{2} ({3}%)":format(srcRes:name, srcRes:amount, srcRes:capacity, round((_srcRes:amount / _srcRes:capacity) * 100)) at (2, 25).
        print "TgtResource: {0}   {1}/{2} ({3}%)":format(tgtRes:name, tgtRes:amount, tgtRes:capacity, round((_tgtRes:amount / _tgtRes:capacity) * 100)) at (2, 26).
    } 
    set _xfr:active to false.
}

local function TestTransfer
{
    parameter _src,
              _tgt,
              _srcRes,
              _amt.

    local srcIdx to
    {
        local i to 0.
        for res in _src:resources 
        {
            if res:name = _srcRes:name
            {
                return i.
            }
            set i to i + 1.
        }
    }.

    

    local resName to _srcRes:name.
    local pctMargin to 0.1.
    local validElements to choose ship:elements:remove(ship:elements:indexOf(_src)) if tgt:length = 0 else list(_tgt).
    from { local i to 0.} until i = validElements:length step { set i to i + 1.} do 
    {
        if validElements[i] <> _src 
        {
            set _tgt to validElements[i].
            
            local tgtIdx to 
            {
                from { local idx to 0.} until idx = _tgt:resources:length step { set idx to idx + 1.} do 
                {
                    local res to _tgt:resources[idx].
                    if res:name = _srcRes:name
                    {
                        return idx.
                    }
                }
            }.
        
            print "Target Element: " + _tgt:name.
            set tgtRes to _tgt:resources[tgtIdx].
            set srcRes to _src:resources[srcIdx].
            
            local xfr to transfer(resName, src, tgt, amt).
            print "Resource: {0}":format(resName) at (2, 25).
            local srcBaseline to srcRes:amount.
            set xfr:active to true.
            wait 0.01.
            until xfr:status <> "Transferring" 
            {
                DispResTransfer2(resName, _src, srcIdx, _tgt, tgtIdx, amt, srcBaseline).
                OutMsg( "Progress: {0}/{1} ({2,3}%)":format(abs(round(srcBaseline - srcRes:amount)), amt, round((srcRes:amount / amt) * 100))).
                print "{0}:  {1}/{2} ({3}%)":format(src:name, round(srcRes:amount, 2), srcRes:capacity, round((srcRes:amount / srcRes:capacity) * 100)) at (2, 29).
                print "{0}:  {1}/{2} ({3}%)":format(tgt:name, round(tgtRes:amount, 2), tgtRes:capacity, round((tgtRes:amount / tgtRes:capacity) * 100)) at (2, 30).
            }
            set xfr:active to false.
        }
    }
}
