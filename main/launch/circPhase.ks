@lazyGlobal off.
clearScreen.

parameter param is list("").

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/disp").

DispMain(scriptPath()).

// Vars
local cTag to core:tag:split("|").
local lp to list().
local lpPath to "".

global MECO to 0.

local volIdx to 1.
until false 
{
    if exists(volIdx + ":/lp.json") 
    {
        set lpPath to volIdx + ":/lp.json".
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        set lpPath to "0:/data/lp.json".
        break.
    }
    else
    {
        set volIdx to volIdx + 1.
    }
}
set lp to readJson(lpPath).


local tgtPe         to lp[0].
local autoDeployPayload to choose false if not param[0] = "deploy" else true.
local payloadStage to choose cTag[1] if cTag:length > 1 else 0.

local rVal to 0.
local sVal to ship:facing.
local tVal to 0.

local avgStageWaitTime to 1.02.

lock steering to sVal.
lock throttle to tVal.

// Arm staging
ArmAutoStaging(payloadStage + 1).

// Calculations
OutMsg("Calculating Burn Parameters").
local dv        to CalcDvBE(ship:periapsis, ship:apoapsis, tgtPe, ship:apoapsis, ship:apoapsis)[1].
local burnDur   to CalcBurnDur(dv).
local fullStageDict to burnDur[2]["Full"].

local totalStages to fullStageDict:keys:length - 1.

local additionalMnvTime to 0.

if (totalStages > 1)
{
    set additionalMnvTime to (totalStages * avgStageWaitTime) / 2.
}

local mnvTime   to time:seconds + eta:apoapsis.
local burnEta   to mnvTime - burnDur[1] - additionalMnvTime.
set MECO      to burnEta + burnDur[0].

OutMsg("Calculation Complete!").
OutInfo("DV Needed: " + round(dv, 1) + "m/s | Burn Duration: " + round(burnDur[0], 1) + "s").
InitWarp(burnEta, "Circularization Burn").
until time:seconds >= burnEta 
{
    set sVal to heading(compass_for(ship, ship:prograde), 0, rVal).
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
until time:seconds >= MECO
{
    set sVal to heading(compass_for(ship, ship:prograde), 0, rVal).
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
ag9 on.
OutInfo().

OutMsg("Circularization phase complete").
wait 1.
ag9 off.

OutWait("Preparing for payload deployment", 5).

// Payload deployment
if autoDeployPayload or ag9
{
    OutMsg("Deploying payload").
    until stage:number = payloadStage 
    {
        if stage:ready stage.
        wait 0.5.
    }
}

OutMsg("Deploying orbital apparatus").
for m in ship:modulesNamed("ModuleRTAntenna") 
{
    if m:part:tag = "" DoEvent(m, "activate").
}

for m in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = "" DoAction(m, "extend solar panel", true).
}

deletePath("1:/lp.json").

OutMsg("Launch complete").