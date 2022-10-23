clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

local _tgtAmt to 100.
local _amtType to "%".
local _margin to 0.10.


local _resName to params[0].
local _src is params[1].
local _srcRes to "".
local _getTgtElements is { parameter _srcEl is _src. local eList to ship:elements:copy. from { local i to ship:elements:length - 1.} until i < 0 step { set i to i - 1.} do { if eList[i]:uid = _srcEl:uid { eList:remove(i).}} return eList. }.
local _tgtElements to _getTgtElements:call().
local _tgtParts to list().
local _tgtRes to lex("amt", 0, "cap", 0, "pct", 0.0, "rMass", 0, "resRefs", list(), "parts", list()).


local _xfrExitCode to 1.

if params:length > 2 
{
    if params[2]:IsType("Element") set _tgtElements to list(params[2]).
    else if params[2]:IsType("List")
    {
        if params[2]:length > 0 
        {
            if params[2][0]:IsType("Part")
            {
                set _tgtParts to params[2].
                for el in ship:elements
                {
                    local doneFlag to false.
                    for p in el:parts
                    {
                        if doneFlag
                        {
                        }
                        else if _tgtParts:contains(p)
                        {
                            if not _tgtElements:contains(el) 
                            {
                                _tgtElements:add(el).
                                set doneFlag to true.
                            }
                        }
                    }
                }
            }
            else if params[2][0]:IsType("Element")
            {
                set _tgtElements to list(params[2]).
            }
        }
    }
}

if _src:IsType("String")
{
    from { local idx to 0.} until idx = ship:elements:length step { set idx to idx + 1.} do
    {
        if ship:elements[idx]:name = _src set _src to ship:elements[idx].
    }
}

for res in _src:resources
{
    if res:name = _resName
    {
        set _srcRes to res.
        break.
    }
}

set _tgtRes to GetTargetResource().
set _tgtParts to _tgtRes:parts.

local _amt to choose min(_srcRes:amount * (1 - _margin), (_tgtRes["cap"] - _tgtRes["amt"] - g_safeMin)) if _amtType = "%" else min(_srcRes:amount * (1 - _margin), _tgtAmt).
local _xfr to transfer(_resname, _srcRes:Parts, _tgtParts, _amt).
OutMsg("Press ENTER to begin transfer").
set _xfr:active to true.
local _done to false.
local _srcBaseline to _srcRes:amount.
set g_termChar to "begin".
wait 0.01. 
until _done
{
    set _done to false.
    set _tgtRes to GetTargetResource().

    if (_srcBaseline - _srcRes:amount) <= 0.1 or _xfr:status <> "Transferring"
    {
        OutInfo("Transfer complete!").
        set _xfr:active to false.
        set _done to true.
        set _xfrExitCode to 0.
        Breakpoint().
    }
    DispResTransfer2(_src, _srcRes, _tgtParts, _tgtRes, _amt, _srcBaseline, _xfr:status).
    GetInputChar().
    wait 0.01.
    if g_termChar = terminal:input:endcursor
    {
        OutMsg("Aborting transfer!").
        set _xfr:active to false.
        set _done to true.
        set _xfrExitCode to 1.
    }
}
OutInfo().
OutMsg("Transfer completed!").




/////////////////////////////
local function GetTargetResource
{
    local _tRes to lex(
        "amt", 0,
        "cap", 0,
        "pct", 0,
        "mass", 0,
        "resRef", list(),
        "parts", list()
    ).

    for el in _tgtElements
    {
        for res in el:resources
        {
            if res:name = _resName
            {
                _tRes:resRef:add(res).
                set _tRes:amt to _tRes:amt + res:amount.
                set _tRes:cap to _tRes:cap + res:capacity.
                
                set _tRes:mass to _tRes:mass + (res:amount * res:density).
                for p in res:parts
                {
                    _tRes:parts:add(p).
                }
                // for p in res:parts
                // {
                //     local activeFlag to true.
                //     for rsrc in p:resources
                //     {
                //         if activeFlag
                //         {
                //             if rsrc:name = _resName
                //             {
                //                 set _tRes["amt"] to _tRes:amt + rsrc:amount.
                //                 set _tRes["cap"] to _tRes:cap + rsrc:capacity.
                //                 set _tRes["rMass"] to _tRes:rMass + (rsrc:amount * rsrc:density).
                //                 _tRes["parts"]:add(p).
                //                 set activeFlag to false.
                //             }
                //             else
                //             {
                //             }
                //         }
                //     }
                // }
                // set _tRes:pct to round(max(g_safeMin, _tRes:amt) / max(g_safeMin, _tRes:cap, 4)).
            }
        }
    }
    set _tRes:pct to round(max(g_safeMin, _tRes:amt) / max(g_safeMin, _tRes:cap), 4).

    return _tRes.
}