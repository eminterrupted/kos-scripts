@lazyGlobal off.

//-- Dependencies
runOncePath("0:/lib/globals").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

//-- Functions

// -- Arming functions
// #region

// ArmBoosterSeparation :: <lexicon> :: <none>
// Sets up a trigger to separate boosters in the boosterLex param when fuel is nearly depleted.
// Works with SRBs and liquid boosters, assuming the liquid booster tank immediately attached 
// to the tagged decoupler does not leak!
global function ArmBoosterSeparation
{
    parameter boosterLex.

    if boosterLex:keys:length > 0
    {
        for idx in boosterLex:keys
        {
            if idx:isType("Scalar") 
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

                    // Check the boosterLex to see if there are any motors in the stage to airstart after previous booster separation
                    // Start them if yes
                    if boosterLex:hasKey("airstart")
                    {
                        if boosterLex["airstart"]:hasKey(bIdx + 1) 
                        {
                            for b in boosterLex["airstart"][bIdx + 1] 
                            {
                                if not b:ignition 
                                {
                                    b:activate.
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
// #endregion

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
    
    if ship:modulesNamed("ModuleCryoTank"):length > 0 
    {
        OutInfo("Setting CryoTank States").
        RestoreTankCooling().
    }

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
        if LfoEngineCheck() 
        {
            IgnitionSequenceStart(launchTime).
            set tVal to 1.
        }
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

// Checks if boost stage is a LFO or SRB stage
local function LfoEngineCheck
{
    for eng in GetEnginesByStage(stage:number - 1)
    {
        if not (eng:ConsumedResources:Keys:Contains("Solid Fuel"))
        {
            return true.
        } 
    }
    OutMsg("Solid first stage detected, disabling throttle-up").
    return false.
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
                    if not DoEvent(m, "retract arm")
                    {
                        DoEvent(m, "retract arms").
                    }
                }
            }
            else if m:part:name:contains("swingarm")
            {
                if not DoEvent(m, "toggle").
                {
                    if not DoEvent(m, "retract arm right").
                    {
                        if not DoEvent(m, "retract arm")
                        {
                            DoEvent(m, "retract arms").
                        }
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
        if m:part:name:contains("CrewWalkwayMercury") animateMod:add(m).
        if m:part:name:contains("CrewElevatorMiniArm") animateMod:add(m).
    }
        
    if animateMod:length > 0
    {
        OutInfo("Retracting crew arm").
        for m in animateMod
        {
            DoEvent(m, "retract arm").
            DoEvent(m, "retract crew arm").
            DoEvent(m, "raise walkway").
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
        if not g:part:name:contains("rtg") or not g:part:title:contains("rtg")
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
    local rofiList to ship:partsNamedPattern("ROFI").

    if rofiList:length > 0 
    {
        OutInfo("Igniting ROFI system").
        for rofi in rofiList 
        {
            rofi:activate.
        }
    }
}

// Launch Escape System - Arm Jettison
global function ArmLESJettison
{
    parameter jettAlt.

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
    
        when ship:altitude >= jettAlt then
        {
            p:activate.
            wait 0.01. 
            if p:thrust > 0 
            {
                p:getModule("ModuleDecouple"):doEvent("Decouple").
                OutInfo("LES Tower Jettisoned").
                g_abortGroup:remove("LES").
                g_abortGroup:remove("LESDecouple").
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

// RestoreTankCooling :: <none> -> <obj>
// Restores cryotanks back to the state found in the cache file (usually what was set in VAB)
global function RestoreTankCooling
{
    local stateCache to path("0:/data/" + ship:name:replace(" ", "_") + "__tankCache.json").
    local cryoTanks to ship:modulesNamed("ModuleCryoTank").
    local cryoState to lex().

    if exists(stateCache)
    {
        set cryoState to readJson(stateCache).
        if cryoState:keys:length > 0
        {
            for m in cryoTanks
            {
                if cryoState:keys:contains(m:part:uid)
                {
                    SetTankCooling(m, cryoState[m:part:uid]).
                }
            }
        }
    }
    deletePath(stateCache).
    return cryoState.
}

// SetTankCooling :: <none> -> <obj>
// Sets the current state of CryoTank active insulation modules in the cache, and returns the data as an object
global function CacheTankCooling
{
    local stateCache to path("0:/data/" + ship:name:replace(" ", "_") + "__tankCache.json").
    local cryoTanks to ship:modulesNamed("ModuleCryoTank").
    local cryoState to lex().
    
    for t in cryoTanks
    {
        if t:hasEvent("disable cooling") set cryoState[t:part:uid] to true.
        else if t:hasEvent("enable cooling") set cryoState[t:part:uid] to false.
    }
    
    if not exists(stateCache) 
    {
        writeJson(cryoState, stateCache).
    }
    return cryoState.
}

// ToggleTankCooling :: <module>, <bool> -> <bool>
// Enables / Disables a CryoTank cooling module based on flag. Returns operation success
global function SetTankCooling
{
    parameter m,
              state.

    if state 
    {
        return DoEvent(m, "enable cooling").
    }
    else
    {
        return DoEvent(m, "disable cooling").
    }
}
//#endregion

// #region -- Abort
// SetupAbortGroup -- <part> -> <bool>
// Creates a global lex of parts / actions involved in a launch abort sequence
// Provide the command module part to abort with, returns a bool if abort system is present
global function SetupAbortGroup
{
    parameter cmdPod. // Part which we want to save in case of abort (i.e., command module with crew)
    
    local LESList to list().
    abort off.

    for p in ship:parts
    {
        if p:name = "LaunchEscapeSystem" or p:name = "restock-engine-les-2" or p:tag = "LES"
        {
            LESList:add(p).
            if p:hasModule("ModuleDecouple") 
            {
                set g_abortGroup["LESDecoupler"] to p:getModule("ModuleDecouple").
            }
        }
        else if p:hasModule("TacSelfDestruct")
        {
            set g_abortGroup["TerminationSystem"] to p:getModule("TacSelfDestruct").
            g_abortGroup["TerminationSystem"]:SetField("time delay", 3).
        }
    }
    if LESList:length > 0 set g_abortGroup["LES"] to LESList.

    for p in cmdPod:children 
    {
        if p:hasModule("ModuleHeatshield")
        {
            for c in p:children
            {
                if c:hasModule("ModuleDecouple")
                {
                    set g_abortGroup["StackDecoupler"] to c:getModule("ModuleDecouple").
                }
            }
        }
    }

    return g_abortGroup:Keys:Length > 0.
}

// LaunchAbortSequence -- <none> -> <bool>
global function InitiateLaunchAbort
{
    if g_abortSystemArmed and ship:body = Body("Kerbin") and ship:periapsis <= ship:body:atm:height / 2
    {
        OutInfo().
        OutInfo2().
        OutTee("MASTER ALARM", 0, 2, 0.5).
        if g_abortGroup:HasKey("TerminationSystem") 
        {
            DoEvent(g_abortGroup:TerminationSystem, "self destruct!").
        }
        if g_abortGroup:HasKey("LES")
        {
            for eng in g_abortGroup:LES
            {
                eng:activate.
            }
        }
        unlock Steering.
        DoEvent(g_abortGroup:StackDecoupler, "decouple").
        
        until ship:availableThrust < 0.1
        {
            OutTee("ABORT SEQUENCE ACTIVATED", 0, 2, 1).
            wait 0.5.
            OutTee("MASTER ALARM", 0, 2, 1).
            wait 0.5.
        }

        until ship:verticalspeed <= 20
        {
            OutTee("ABORT SEQUENCE ACTIVATED", 0, 2, 1).
            wait 0.5.
            OutTee("MASTER ALARM", 0, 2, 1).
            wait 0.5.
        }
        lock Steering to ship:SrfRetrograde.
        if g_abortGroup:hasKey("LESDecoupler") 
        {
            DoEvent(g_abortGroup:LESDecoupler, "decouple").
        } 
        wait 0.5.
        for m in ship:ModulesNamed("RealChuteModule")
        {
            DoEvent(m, "arm parachute").
        }

        until false
        {
            OutTee("MASTER ALARM", 0, 2, 1).
            wait 0.5.
        }
    }
}