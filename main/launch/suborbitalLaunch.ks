@lazyGlobal off.
clearScreen.

// #include "0:/boot/_bl.ks"

parameter lPlan to list().

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
local tgtPe     to 42500.
local tgtAp     to 250000.
local tgtInc    to -45.
local tgtLAN    to -1.
local tgtRoll   to 180.

// If the launch plan was passed in via param, override manual values
if lPlan:length > 0
{
    set tgtAp to lPlan[0].
    set tgtPe to lPlan[1].
    set tgtInc to lPlan[2].
    set tgtLAN to lPlan[3].
    set tgtRoll to lPlan[4]. 
}
else 
{
    set lPlan to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).
}
local lpCache to list(tgtPe, tgtAp, tgtInc, tgtLAN, tgtRoll).

// Turn params
local altRoll       to ship:altitude + 250.
local altStartTurn  to ship:altitude + 750.
local altGravTurn   to 45000.
local altFlatTrajectory to ship:body:atm:height * 0.80.
local runMode to -1.
local spdStartTurn  to 75.

// Vessel systems / control
local boosterObj to lex().
local rVal to tgtRoll.
local stageLimit to g_stopStage.
local ts to 0.

// Azimuth
local azCalcObj to list().

// Optional second core
local core2 to "".

OutHUD("Launch plan validation", 0, 2.5).

// Begin  
LaunchPadGen(true).
lock steering to sVal. 

DispLaunchPlan(lpCache, list(plan:toupper, branch:toupper)).

// Write tgtPe and tgtInc to the local drive. 
// If write fails, iterate through volumes. If no other volumes, write to archive.
local volIdx to 1. 
until false
{
    writeJson(list(tgtPe, tgtInc), volIdx + ":/lp.json").
    if exists(volIdx + ":/lp.json") 
    {
        break.
    }
    else if volIdx = ship:modulesNamed("kOSProcessor"):length 
    {
        writeJson(list(tgtPe, tgtInc), "0:/data/lp.json").
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
    // We need to retract Soyuz launch pad elements if present before handing off to launchIntoLAN
    if ship:partsDubbedPattern("mlp.soyuz"):length > 0 RetractSoyuzGantry().
    runPath("0:/util/launchIntoLAN", tgtInc, tgtLAN).
}
else
{
    set ts to time:seconds.
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
            OutTee("Press Enter in terminal to confirm launch", 0, 2.5).
            set ts to time:seconds + 5.
        }
        wait 0.05.
    }
    // Retract Soyuz launch pad elements if present AFTER user presses enter 
    // (avoids long wait times while gantry retracts)
    // Gets any special saturn or soyuz auxiliary launch pad parts that need special early handling
    local padAuxParts to ship:partsNamedPattern("AM.MLP.*(Crane|DamperArm|CrewElevatorGemini|SoyuzLaunchBaseGantry|SoyuzLaunchBaseArm)").
    if padAuxParts:length > 0 
    {
        RetractAuxPadStructures(padAuxParts, true).
    }
}

// Setup the terminal
clearScreen.
DispMain(scriptPath(), false).

until runmode > 99
{


    if runmode = -1
    {
        // Get booster on vessel, if any
        set boosterObj to GetBoosters().

        // Arm systems
        ArmAutoStaging(stageLimit).
        ArmLESJettison(62500).
        ArmFairingJettison("ascent", body:atm:height - 5000, "launch").
        set g_boosterSystemArmed to ArmBoosterSeparation(boosterObj).
        set g_abortSystemArmed to SetupAbortGroup(Ship:RootPart).
        ArmEngCutoff().

        // Calculate AZ here
        set azCalcObj to l_az_calc_init(tgtAp, tgtInc).

        set sVal to ship:facing.
        set runmode to 4.
    }


    else if runmode = 4
    {
        // Countdown to launch
        LaunchCountdown(10).

        // Launch commit
        set tVal to 1.
        lock throttle to tVal.
        HolddownRetract().
        if missionTime <= 0.01 stage.  // Release launch clamps at T-0.

        if core2 <> "" 
        {
            SendMsg(core2, "CountdownComplete"). // A flag used for other scripts to denote that launch has occured
        }
        set runmode to 9.

        OutInfo().
        OutInfo2().
    }


    else if runmode = 8
    {
        OutMsg("Vertical Ascent").
        set runmode to 9.
    }


    else if runmode = 9
    {
        if ship:altitude >= altRoll
        {
            set runmode to 13.
            OutInfo("Roll Program").
        }
    }


    else if runmode = 13
    {
        set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
        set runmode to 14.
    }


    else if runmode = 14
    {
        if steeringManager:rollerror <= 0.1 and steeringManager:rollerror >= -0.1
        {
            set runmode to 17.
        }
    }


    if runMode = 17
    {
        if ship:altitude >= altStartTurn or ship:verticalspeed >= spdStartTurn or g_engBurnout
        {
            set altStartTurn to ship:altitude.
            set runmode to 19.
            OutMsg("Pitch Program").
        }
        else
        {
            set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
        }
    }


    else if runmode = 19
    {
        if ship:altitude >= altFlatTrajectory or (g_engBurnout and stage:number = g_stopStage)
        {
            set runmode to 21.
            OutMsg("Horizontal Velocity Program").
        }
        else
        {   
            set sVal to heading(l_az_calc(azCalcObj), LaunchAngForAlt(altGravTurn, altStartTurn, 0), rVal).
            DispTelemetry().
            wait 0.01.
        }
    }


    else if runmode = 21
    {
        if ship:apoapsis >= tgtAp * 0.9995 or (g_engBurnout and stage:number = g_stopStage)
        {
            set runmode to 24.
        }
        else
        {
            local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
            local adjAng to max(0, lAng - ((ship:altitude - altGravTurn) / 1000)).
            set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
            DispTelemetry().
            wait 0.01.
        }
    }


    else if runmode = 24
    {
        if ship:apoapsis >= tgtAp or (g_engBurnout and stage:number = g_stopStage)
        {
            set runmode to 27.
        }
        else
        {
            local lAng to LaunchAngForAlt(altGravTurn, altStartTurn, 0).
            local adjAng to lAng - ((ship:altitude - altGravTurn) / 1000).
            set sVal to heading(l_az_calc(azCalcObj), adjAng, rVal).
            DispTelemetry().
            wait 0.01.
        }
    }


    else if runmode = 27
    {
        set tVal to 0.
        OutInfo("Engine Cutoff").
        wait 0.25.
        if ship:apoapsis > ship:body:atm:height 
        {
            set runmode to 31.
            OutMsg("Coasting to space").
        }
        else 
        {
            set ts to time:seconds + 15.
            set runmode to 33.
        }
    }
    

    else if runmode = 31
    {
        set g_orientation to "pro-body".
        if ship:altitude > ship:body:atm:height
        {
            set ts to time:seconds + 15.
            set runmode to 33.
        }
    }


    else if runmode = 33
    {
        Set runmode to 35.
        OutMsg("Coasting to staging altitude").
    }


    else if runmode = 35
    {
        if time:seconds >= ts or time:seconds > ship:apoapsis:eta - 10
        {
            set runmode to 39.
            OutMsg("Waiting for booster staging").
        }
    }


    else if runmode = 39
    {
        OutMsg("Booster staging").
        local coastStage to g_stopStage.
        until stage:number = coastStage
        {
            wait until stage:ready.
            stage.
        }
        set ts to time:seconds + 2.5.
        set runmode to 42.
        OutMsg("Booster staged").
    }


    else if runmode = 42
    {
        if time:seconds > ts
        {
            set ts to time:seconds + eta:apoapsis.
            InitWarp(ts, "near apoapsis").
            
            set runmode to 45.
            OutMsg("Coasting to apoapsis").
        }
    }


    else if runmode = 45
    {
        if ship:crew:length > 0
        { 
            unlock steering.
            wait 1.
            set runmode to 48.
        }
        else
        {
            set ts to time:seconds + eta:apoapsis - 30.
            InitWarp(ts, "near apoapsis").

            set runmode to 48.
        }
    }


    else if runmode = 48
    {
        if time:seconds >= ts
        {
            set runmode to 99.
        }
    }
    

    else if runmode = 99
    {
        sas off.
        OutMsg("Suborbital script complete").
        wait 2.5.
    }
    
    if g_abortSystemArmed and abort InitiateLaunchAbort().
    if runmode > 27 set sVal to GetSteeringDir(g_orientation).
    DispTelemetry().
    wait 0.01.
}


// else if runmode = 81
// {
//     until MasterAlarm("Apoapsis still in atmosphere!", 0, true)
//     {
//         set sVal to GetSteeringDir(g_orientation).
//         DispTelemetry().
//         wait 0.01.
//     }
// }