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
local orientation to "pro-sun".

local runmode to 0.

if param:length > 0 
{
    set tgt to GetOrbitable(param[0]).
    if param:length > 1 set orientation to param[1].
}

// If we haven't yet supplied a target, and we have a target in the system, use it
if hasTarget and tgt = ship
{
    set tgt to target.
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

until runmode = -1
{
    set sVal to GetSteeringDir(orientation).
    
    if runmode = 0 
    {
        if tgt <> ship 
        {
            set runmode to 10.
        }
        else
        {
            OutTee("Already in SOI", 1).
            break.
        }
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
            set g_termChar to GetInputChar().

            if g_termChar = Terminal:Input:Enter
            {
                InitWarp(time:seconds + ship:orbit:nextpatcheta, "SOI Change", 3, true).
            }
                
            local soiDispData to DispSOIData().
            DispGeneric(soiDispData, 10).
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
    else
    {
        paramList:add("Next").
        paramList:add("NONE").
        paramList:add("ETA").
        paramList:add("INF").
    }
    return paramList.
}