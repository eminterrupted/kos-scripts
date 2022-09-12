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

Terminal:Input:Clear.
until runmode = -1
{
    set sVal to GetSteeringDir(orientation).
    
    set g_termChar to GetInputChar().

    if g_termChar = terminal:input:endcursor
    {
        OutTee("Terminating WaitForSOI").
        set runmode to -1.
    }

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
        if ship:body:name = tgt:name or (tgt:isType("Vessel") and ship:body:name = tgt:body:name)
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
            if g_termChar = Terminal:Input:Enter
            {
                InitWarp(time:seconds + ship:orbit:nextpatcheta, "SOI Change", 3, true).
            }
                
            DispSOIData(tgt).
            //DispGeneric(soiDispData, 10).
        }
    }
    else if runmode = 15
    {
        OutMsg("Target SOI Reached").
        set runmode to -1.
    }
    set g_termChar to "".
}