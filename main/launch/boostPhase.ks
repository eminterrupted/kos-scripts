@lazyGlobal off.
clearScreen.

parameter lp to list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_l_az_calc.ks").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/globals").

DispMain(scriptPath(), false).

// Vars
// Launch params
local tgtPe     to 1250000.
local tgtAp     to 1250000.
local tgtInc    to 0.
local tgtLAN    to -1.
local tgtRoll   to 0.

// If the launch plan was passed in via param, override manual values
if lp:length > 0
{
    set tgtPe to lp[0].
    set tgtAp to lp[1].
    set tgtInc to lp[2].
    set tgtLAN to lp[3].
    set tgtRoll to lp[4]. 
}
else 
{
    set lp to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).
}
local lpCache to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).

// Turn params
local altStartTurn to 750.
local altGravTurn  to 50000.
local spdStartTurn to 75.

// Boosters
local boosterLex to lex().
local hasBoosters to false.

// Controls
local rVal to tgtRoll.
local sVal to ship:facing.
local tVal to 0.

// Core tag
local cTag to core:tag.
local stageLimit to choose 0 if cTag:split("|"):length <= 1 else cTag:split("|")[1].
// Optional second core
local core2 to "".

// Begin  
LaunchPadGen(true).
lock steering to sVal. 

DispLaunchPlan(lpCache).

// Write tgtPe to the local drive. If write fails, iterate through volumes. If no other volumes, write to archive.
local volIdx to 1. 
until false
{
    writeJson(list(tgtPe), volIdx + ":/lp.json").
    if exists(volIdx + ":/lp.json") 
    {
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        writeJson(list(tgtPe), "0:/data/lp.json").
        break.
    }
    else
    {
        set volIdx to volIdx + 1.
    }
}

// Wait for specific LAN goes here
if tgtLAN > -1
{
    runPath("0:/util/launchIntoLAN", tgtInc, tgtLAN).
}
else
{
    local ts to time:seconds.
    until false
    {
        if CheckInputChar(terminal:input:enter) break.
        local msgs to CheckMsgQueue().
        if msgs:contains("launchCommit") 
        {
            set core2 to msgs[1].
            break.
        }
        else if time:seconds >= ts
        {
            OutTee("Press Enter in terminal to launch", 0, 2.5).
            set ts to time:seconds + 5.
        }
        wait 0.05.
    }
}
clearScreen.
DispMain(scriptPath(), false).

// Booster check
for p in ship:parts
{
    if p:tag:contains("booster") 
    {
        local pIdx to p:tag:split(".")[1]:tonumber.
        set hasBoosters to true.
        if boosterLex:hasKey(pIdx) 
        {
            boosterLex[pIdx]:add(p).
        }
        else
        {
            set boosterLex[pIdx] to list(p).
        }
    }
}

// Arm staging
ArmAutoStaging(stageLimit).

if hasBoosters
{
    for idx in boosterLex:keys
    {
        local bIdx to idx.
        when boosterLex[bIdx][0]:children[0]:resources[0]:amount <= 0.05 then 
        {
            OutInfo("Detaching Booster: " + bIdx).
            for dc in boosterLex[bIdx]
            {
                if dc:partsDubbedPattern("sep"):length > 0 
                {
                    for sep in dc:partsDubbedPattern("sep") sep:activate.
                }
                local m to choose "ModuleDecouple" if dc:modulesNamed("ModuleDecoupler"):length > 0 else "ModuleAnchoredDecoupler".
                if dc:modules:contains(m) DoEvent(dc:getModule(m), "decouple").
            }
            wait 1.
            OutInfo().
        }
    }
}

// Calculate AZ here, write to disk for circularization. 
// We will write this to disk along with tgtPe and boost stage at launch
local azCalcObj to l_az_calc_init(tgtAp, tgtInc).

// Countdown to launch
LaunchCountdown(10).

// Launch commit
set tVal to 1.
lock throttle to tVal.
HolddownRetract().
if missionTime <= 0.01 stage.  // Release launch clamps at T-0.
if core2 <> "" 
{
    SendMsg(core2, "CountdownComplete").
}.    // A flag used for other scripts to denote that launch has occured

OutInfo().
OutInfo2().

OutMsg("Vertical Ascent").
until ship:altitude >= 150
{
    DispTelemetry().
    wait 0.01.
}

OutInfo("Roll Program").
set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
until steeringManager:rollerror <= 0.1 and steeringManager:rollerror >= -0.1
{
    DispTelemetry().
    wait 0.01.
}
OutInfo().

until ship:altitude >= altStartTurn or ship:verticalspeed >= spdStartTurn 
{
    DispTelemetry().
    wait 0.01.
}
set altStartTurn to ship:altitude.

OutMsg("Pitch Program").
until (ship:altitude >= altGravTurn and ship:apoapsis >= tgtAp * 0.5) or ship:apoapsis >= tgtAp * 0.975
{
    set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), rVal).
    DispTelemetry().
    wait 0.01.
}


OutMsg("Horizontal Velocity Program").
until ship:apoapsis >= tgtAp * 0.9995
{
    local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
    local adjAng to max(0, lAng - ((ship:altitude - altGravTurn) / 1000)).
    set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
    DispTelemetry().
    wait 0.01.
}
set tVal to 0.
OutInfo("Engine Cutoff").

OutMsg("Boost phase complete").