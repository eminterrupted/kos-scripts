@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local _conditionType to "".
local _tgtObj to "".
local _ves to "".
local _thresh to 2.5.

// Parse Params
if params:length > 0 
{
  set _conditionType to params[0].
  if params:length > 1 set _tgtObj to params[1].
  if params:length > 2 set _ves to params[2].
  if params:length > 3 set _thresh to params[3].
}

if _conditionType = "ap"
{

}
else if _conditionType = "pe"
{

}
else if _conditionType = "inc"
{
    if CheckValDeviation(_ves:orbit:inclination, _tgtObj:orbit:inclination, _thresh)
    {
        wait 1.
        if (_tgtObj:orbit:inclination > -2.5 and _tgtObj:orbit:inclination < 2.5) or CheckValDeviation(_ves:orbit:lan, _tgtObj:orbit:lan, _thresh, 360)
        {
            OutMsg("Condition check passed, popping next script").
            runPath("0:/util/mpPop").
        }
        else
        {
            OutMsg("Condition Check failed, proceeding to next script").
            wait 0.25.
        }
    }
    else
    {
        OutMsg("Condition Check failed, proceeding to next script").
        wait 0.25.
    }
}
else if _conditionType = "argpe"
{

}
else if _conditionType = "orbit"
{

}