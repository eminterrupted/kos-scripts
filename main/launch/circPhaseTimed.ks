@lazyGlobal off.
clearScreen.

parameter lp to readJson("1:/lp.json").

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/kslib/lib_l_az_calc").

DispMain(scriptPath()).

// Vars
local azCalcObj to lp["azCalcObj"].
local tgtPe to lp["tgtPe"].
local deployPayload to true.

local burnBeforeApoSecs to 30.

local rVal to 0.
local sVal to ship:facing.
local tVal to 0.

lock steering to sVal.
lock throttle to tVal.

// Arm staging
//ArmAutoStaging(1).

OutMsg("Circularization phase").

// Solid-booster insertion
OutMsg("Coast phase").

InitWarp(time:seconds + eta:apoapsis - burnBeforeApoSecs, "burn start", 5).

until eta:apoapsis <= burnBeforeApoSecs
{
    OutInfo("Orbital insertion in: " + round(eta:apoapsis - burnBeforeApoSecs, 1)).
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).
    DispTelemetry().
    wait 0.1.
}

OutMsg("Orbital insertion phase").
OutInfo().
set tVal to 1.
wait 0.05.

local engs to GetEngines().
until ship:periapsis >= tgtPe * 0.975 or (stage:number = 1 and ship:availablethrust < 0.1)
{
    set sVal to heading(l_az_calc(azCalcObj), 0, rVal).

    if stage:number > 1 and GetTotalThrust(engs) <= 0.1
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