@lazyGlobal off.

//-- Dependencies
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

//-- Functions

//#region -- Ascent functions
// Set pitch by deviation from a reference pitch
global function LaunchAngForAlt
{
    parameter turnAlt,
              startAlt,
              endPitch,
              pitchLim is 5.
    
    // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
    local pitch     to max(endPitch, 90 * (1 - ((ship:altitude - startAlt) / (turnAlt - startAlt)))). 
    // local pg to ship:srfprograde:vector.

    local pg        to choose ship:srfPrograde:vector if ship:body:atm:altitudepressure(ship:altitude) * constant:atmtokpa > 0.01 else ship:prograde:vector.
    local pgPitch   to 90 - vang(ship:up:vector, pg).
    //set pitchLim    to choose pitchLim if ship:body:atm:altitudePressure(ship:altitude) * constant:atmtokpa > 0.0040 else pitchLim * 5.
    // Calculate the effective pitch with a 5 degree limiter
    local effPitch  to max(pgPitch - pitchLim, min(pitch, pgPitch + pitchLim)).
    return effPitch.
}.
//#endregion

//#region -- Countdown and Launch pad functions
// Launch countdown
global function LaunchCountdown
{
    parameter s is 15.

    local tVal to 0.
    lock throttle to tVal.

    local launchTime to time:seconds + s.
    lock countdown to time:seconds - launchTime. 
    
    OutInfo("Countdown initiated").

    FallbackRetract(1).
    CrewArmRetract().
    RetractSoyuzFuelArm().

    until countdown >= -10 
    {
        OutMsg("COUNTDOWN: " + round(countdown, 1)).
        wait 0.1.
    }    

    until countdown >= -8
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.1.
    }
    PadROFI().

    until countdown >= -6
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.1.
    }
    LaunchPadGen(false).

    until countdown >= -1.5
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.1.
    }

    if ship:status = "PRELAUNCH" 
    {
        IgnitionSequenceStart(launchTime).
        set tVal to 1.
    }
    OutInfo2().

    LaunchArmRetract().
    FallbackRetract(2).

    until countdown >= 0
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.01.
    }
    unlock countdown.
}

// Engine startup sequence
global function IgnitionSequenceStart
{
    parameter cdEngStart.

    local tVal to 0.25.
    lock throttle to tVal.
    
    stage.
    until tVal >= .99
    {
        OutMsg("COUNTDOWN T" + round(time:seconds - cdEngStart, 1)).
        OutInfo("Engine Start Sequence").
        OutInfo2("Throttle: " + round(tVal * 100) + "% ").
        set tVal to tVal + 0.0275.
        wait 0.025.
    }
}

// Drops umbilicals and retracts swing arms
global function LaunchArmRetract
{
    local animateMod to list().  // Main list
    
    for m in ship:modulesNamed("ModuleAnimateGenericExtra")  // Swing arms that are not crew arms
    {
        if not m:part:name:contains("CrewArm") animateMod:add(m).
    }
    
    for m in ship:modulesNamed("ModuleAnimateGeneric")  // Add Umbilicals
    {
        if m:hasEvent("drop umbilical") animateMod:add(m).
    }
    
    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("umbilical")
            {
                if not DoEvent(m, "drop umbilical")
                {
                    DoEvent(m, "retract arm").
                }
            }
            else if m:part:name:contains("swingarm")
            {
                if not DoEvent(m, "toggle").
                {
                    if not DoEvent(m, "retract arm right").
                    {
                        DoEvent(m, "retract arm").
                    }
                }
            }
        }
    }
}

// Retracts a crew arm
global function CrewArmRetract
{
    local animateMod to list().  // Main list
    
    for m in ship:modulesNamed("ModuleAnimateGenericExtra")  // Swing arms that are not crew arms
    {
        if m:part:name:contains("CrewArm") animateMod:add(m).
    }
        
    if animateMod:length > 0
    {
        OutInfo("Retracting crew arm").
        for m in animateMod
        {
            if not DoEvent(m, "retract arm").
            {
                DoEvent(m, "retract crew arm").
            }
        }
    }
}

// Fallback tower
global function FallbackRetract
{
    parameter state is 0.

    local animateMod to ship:modulesNamed("ModuleAnimateGenericExtra").
    local clampEvent to "open upper clamp".
    local genericEvent to "retract tower".
    local fallbackEvent to choose "full retract tower step 2" if state = 2 else "partial retract tower step 1".

    if animateMod:length > 0 
    {
        for m in animateMod
        {
            if state = 2 and m:hasEvent(genericEvent) DoEvent(m, genericEvent).
            else if m:hasEvent(fallbackEvent) DoEvent(m, fallbackEvent).
            else if m:hasEvent(clampEvent) 
            {
                DoEvent(m, clampEvent).
                wait until m:getField("status") = "Locked".
            }
        }
    }
}

// Toggles launchpad generator
global function LaunchPadGen
{
    parameter powerOn.

    local genList   to ship:modulesNamed("ModuleGenerator").
    for g in genList
    {
        if powerOn 
        {
            OutInfo("Vehicle on external power").
            DoEvent(g, "activate generator").
        }
        else 
        {
            OutInfo("Vehicle on internal power").
            DoEvent(g, "shutdown generator").
        }
    }
}

// Hold downs retract
global function HolddownRetract
{
    local animateMod to ship:modulesNamed("ModuleAnimateGenericExtra").
    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("hold")
            {
                DoEvent(m, "retract arm").
            }
            else if m:part:name:contains("SaturnLauncherTSM")
            {
                DoEvent(m, "retract arm").   
            }
            else if m:part:name:contains("SoyuzLaunchBaseClampArm")
            {
                DoEvent(m, "retract clamp arm").
            }
        }
    }
}

// ROFI sparklers
global function PadROFI
{
    local rofiList to ship:partsNamed("AM_MLP_GeneralROFI").

    if rofiList:length > 0 
    {
        OutInfo("Igniting ROFI system").
        for r in rofiList 
        {
            r:activate.
        }
    }
}

// Launch Escape System - Arm Jettison
global function ArmLESJettison
{
    local lesList to list().
    for p in ship:parts
    {
        if p:name = "LaunchEscapeSystem" or p:name = "restock-engine-les-2" or p:tag = "LES"
        {
            lesList:add(p).
        }
    }
    
    if (lesList:length > 0)
    {
        local p to lesList[0].
    
        when ship:altitude >= 80000 then
        {
            p:activate.
            wait 0.01. 
            if p:thrust > 0 
            {
                p:getModule("ModuleDecouple"):doEvent("Decouple").
                OutInfo("LES Tower Jettisoned").
            }
            else
            {
                OutInfo("CAUTION: LES Engines Failed").
            }
        }
    }
}

// Retracts MLP Soyuz-style Gantry arms and waits for retraction to complete
global function RetractSoyuzGantry
{
    local pList to list().
    for p in ship:parts
    {
        if p:name:contains("SoyuzLaunchBaseGantry") pList:add(p).
    }

    if pList:length > 0
    {
        local gMod to "".
        OutMsg("Retracting gantry arms").
        for p in pList
        {
            for m in p:modulesNamed("ModuleAnimateGenericExtra")
            {
                if m:hasEvent("retract gantry arms") 
                {
                    set gMod to m.
                    DoEvent(m, "retract gantry arms").
                }
            }
        }

        until gMod:GetField("status") = "locked"
        {
            wait 0.1.
        }
        OutMsg("Retraction complete").
    }
}

// Retract MLP Soyuz-style fuel arms
global function RetractSoyuzFuelArm
{
    local pList to list().
    for p in ship:parts
    {
        if p:name:contains("SoyuzLaunchBaseArm") pList:add(p).
    }

    if pList:length > 0
    {
        for p in pList
        {
            for m in p:modulesNamed("ModuleAnimateGenericExtra")
            {
                DoEvent(m, "retract arm").
            }
        }
    }
}

// 🎅 Seasons Yeetings Fairings 🎄--
global function ArmFairingJettison
{
    if (ship:modulesnamed("ModuleProceduralFairing"):length > 0)
    {
        when ship:altitude >= body:atm:height then
        {
            for module in ship:modulesnamed("ModuleProceduralFairing")
            {
                module:doevent("deploy").
                wait 0.05.
            }
        }
    }
}
//#endregion