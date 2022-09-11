@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/mnv").
RunOncePath("0:/lib/burnCalc").

DispMain(ScriptPath():name).

// Declare Variables
local burnDv to list().
local burnETA to 0.
local burnTA to 0.
local circAt to "ap".
local circTgt to 0.
local compMode to "pe".
local mnvDv to 0.
// local tgtAp to 0.
// local tgtPe to 0.

// Parse Params
if params:length > 0 
{
  set circAt to params[0].
}

until not hasNode
{
    remove nextNode.
    wait 0.01.
}

if circAt = "ap"
{
    // set tgtAp to round(ship:apoapsis).
    // set tgtPe to tgtAp.
    set circTgt to round(ship:apoapsis).
    set burnTA to 180.
    set compMode to "pe".
    OutMsg("Circularizing at apoapsis ({0})":format(circTgt)).
}   
else if circAt = "pe"
{
    //set tgtPe to round(ship:periapsis).
    //set tgtAp to tgtPe.
    set circTgt to round(ship:periapsis).
    set burnTA to 0.
    set compMode to "ap".
    OutMsg("Circularizing at periapsis ({0})":format(circTgt)).
}
else
{
    OutTee("Unrecognized parameter: " + circAt, 0, 2).
    wait 2.
    print 0 / 1.
}
set burnETA to ETAtoTA(ship:orbit, burnTA).
//set burnDv to CalcDvHoh2(ship:periapsis, ship:apoapsis, tgtPe, tgtAp, ship:body, burnTA).
//set burnDV to CalcDvHoh(ship:periapsis, ship:apoapsis, circTgt, ship:body, circAt).
//set burnDv to CalcDvBE(ship:periapsis, ship:apoapsis, circTgt, circTgt, ship:apoapsis, ship:body, circAt).
set burnDv to CalcDvBE(ship:periapsis, ship:apoapsis, circTgt, circTgt, circTgt, Ship:Body, "pe").
print burnDv at (2, 25).
set mnvDv to choose burnDv[1] if circAt = "ap" else -burnDv[0].
wait 0.25.

add node(TimeSpan(burnETA), 0, 0, mnvDv).

Breakpoint(). 

ExecNodeBurn(nextNode).

OutMsg("circ.ks complete").