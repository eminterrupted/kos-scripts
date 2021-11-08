@lazyGlobal off.
clearScreen.

parameter lp to readJson("1:/lp.json").

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/disp").

DispMain(scriptPath()).

// Vars
local azCalcObj     to lp["azCalcObj"].
local tgtPe         to lp["tgtPe"].
local deployPayload to true.

local rVal to 0.
local sVal to ship:facing.
local tVal to 0.

lock steering to sVal.
lock throttle to tVal.

// Arm staging
ArmAutoStaging(0).

// Calculations
OutMsg("Calculating Burn Parameters").
local dv        to CalcDvBE(ship:periapsis, ship:apoapsis, tgtPe, ship:apoapsis, ship:apoapsis)[1].
local burnDur   to BurnDur(dv).
local mnvTime   to time:seconds + eta:apoapsis.
local burnEta   to mnvTime - burnDur[1].
local MECO      to burnEta + burnDur[0].

OutMsg("Calculation Complete!").
OutInfo("DV Needed: " + round(dv, 1) + "m/s | Burn Duration: " + round(burnDur[0], 1) + "s").
InitWarp(burnEta, "Circularization Burn").
until time:seconds >= burnEta 
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    OutInfo2("Burn ETA: " + round(burnEta - time:seconds, 1) + "s     ").
    DispTelemetry().
    wait 0.01.
}

OutMsg("Orbital insertion phase").
OutInfo().
OutInfo2().
set tVal to 1.
wait 0.05.

local engs to GetEngines().
until ship:periapsis >= tgtPe * 0.975 or (stage:number = 0 and ship:availablethrust < 0.1)
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    OutInfo("Est time to MECO: " + round(MECO - time:seconds, 1) + "s   ").
    if stage:number > 0 and GetTotalThrust(engs) <= 0.1
    {
        OutInfo("Circ Staging").
        if stage:ready stage.
        set engs to GetEngines().
        OutInfo().
    }
    DispTelemetry().
    wait 0.01.
}
set tVal to 0.
OutInfo().

OutMsg("Circularization phase complete").
wait 1.

// Payload deployment
if deployPayload 
{
    OutMsg("Deploying payload").
    until stage:number = 0 
    {
        if stage:ready stage.
        wait 0.5.
    }
}

OutMsg("Deploying orbital apparatus").
for m in ship:modulesNamed("ModuleRTAntenna") 
{
    DoEvent(m, "activate").
}

OutMsg("Launch complete").