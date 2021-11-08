@lazyGlobal off.
clearScreen.

parameter tgtPe to 750000,
          tgtAp to 750000,
          tgtInc to 0,
          tgtLAN to 0.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_l_az_calc.ks").

DispMain(scriptPath()).

// Vars
local altStartTurn to 750.
local altGravTurn  to 50000.
local spdStartTurn to 75.

local boosterLex to lex().
local hasBoosters to false.

local rVal to 0.
local sVal to heading(0, 90, 0).
local tVal to 0.

// Begin  
LaunchPadGen(true).
lock steering to sVal. 
ag10 off.

// Wait for specific LAN goes here
local ts to time:seconds.
until false
{
    if CheckInputChar(terminal:input:enter) break.
    else if time:seconds >= ts
    {
        OutTee("Press Enter in terminal to launch", 0, 2.5).
        set ts to time:seconds + 5.
    }
    wait 0.05.
}

// Booster check
for p in ship:parts
{
    if p:tag:contains("booster") 
    {
        set hasBoosters to true.
        if boosterLex:hasKey(p:tag) 
        {
            boosterLex[p:tag]:add(p).
        }
        else
        {
            set boosterLex[p:tag] to list(p).
        }
    }
}

// Arm staging
ArmAutoStaging(1).

if hasBoosters
{
    for b in boosterLex:keys
    {
        when boosterLex[b][0]:children[0]:resources[0]:amount <= 0.01 then 
        {
            for dc in boosterLex[b]
            {
                DoEvent(dc:getModule("ModuleDecouple"), "decouple").
            }
        }
    }
}

// Calculate AZ here, write to disk for circularization
local azCalcObj to l_az_calc_init(tgtAp, tgtInc).
local lpCache to lex("tgtPe", tgtPe, "azCalcObj", azCalcObj).
writeJson(lpCache, "1:/lp.json").

// Countdown to launch
LaunchCountdown(10).

// Launch commit
set tVal to 1.
lock throttle to tVal.
HolddownRetract().
if missionTime <= 0.01 stage.  // Release launch clamps at T-0.
ag10 off.   // Reset ag10 (is true to initiate launch)
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
until (ship:altitude >= altGravTurn and ship:apoapsis >= body:atm:height + 10000) or ship:apoapsis >= tgtAp * 0.975
{
    set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), rVal).
    DispTelemetry().
    wait 0.01.
}


OutMsg("Horizontal Velocity Program").
until ship:apoapsis >= tgtAp * 0.9995 or eta:apoapsis <= 10
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