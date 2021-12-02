@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

local lastBody to ship:body.
local tgt to ship.
local soiBody to ship:body.
local orientation to "pro-sun".

local runmode to 0.
local warpFlag to true.

local sVal to ship:facing.
lock steering to sVal.

if hasTarget 
{
    set tgt to target.
}
else if param:length > 0 
{
    set tgt to GetOrbitable(param[0]).
    if param:length > 1 set soiBody to GetOrbitable(param[1]).
    if param:length > 2 set orientation to param[2].
}

until runmode = -1
{
    if runmode = 0 
    {
        if tgt <> ship 
        {
            set runmode to 5.
        }
        else
        {
            OutTee("Already in SOI", 1).
            break.
        }
    }

    else if runmode = 5
    {
        InitWarp(time:seconds + ship:orbit:nextpatcheta, "SOI Change", 5).
        set warpFlag to true.
        set runmode to 10.
    }

    else if runmode = 10
    {
        if ship:body:name = tgt:name
        {
            set runmode to 15.
        }
        else if lastBody <> ship:body
        {
            OutMsg("Reached SOI: " + ship:body).
            set lastBody to ship:body.
        }    
        else 
        {
            if warp = 0 and not warpFlag
            {
                set runmode to 5.
            }
            else
            {
                local soiDispData to DispSOIData.
                DispGeneric(soiDispData, 10).
            }
        }
    }
    else if runmode = 15
    {
        OutMsg("Target SOI Reached").
        set runmode to -1.
    }
}

local function DispSOIData
{
    local paramList to list("SOI Information", "Current", ship:body:name, "Target", tgt:name).
    if ship:orbit:hasnextpatch
    {
        paramList:add("Next").
        paramList:add(ship:orbit:nextPatch:body:name).
        paramList:add("ETA").
        paramList:add(timeSpan(ship:orbit:nextpatcheta):full).
    }
    return paramList.
}
    
