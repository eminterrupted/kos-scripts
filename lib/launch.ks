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
                when boosterLex[bIdx][0]:children[0]:resources[boosterLex[bIdx][0]:children[0]:resources:length - 1]:amount <= 0.05 then 
                {
                    set boosterLex to GetBoosters().
                    if boosterLex:hasKey(bIdx)
                    {
                        OutInfo("Detaching Booster: " + bIdx).
                        for dc in boosterLex[bIdx]
                        {
                            if dc:partsDubbedPattern("(sep|pc.nose|pc_nose)"):length > 0
                            {
                                for sep in dc:partsDubbedPattern("(sep|pc.nose|pc_nose)") sep:activate.
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
                    else
                    {
                        OutTee("Booster staging failure in bIdx: {0}":format(bIdx), 1, 1).
                    }
                }
            }
        }
    }
}
// #endregion

//#region -- Ascent functions
// Set pitch by deviation from a reference pitch for orbital launches
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

// Set pitch by deviation from a reference pitch
global function SuborbitalAscentProfile
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

    until countdown >= -2.35
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.1.
    }

    if ship:status = "PRELAUNCH"
    {
        if LfoEngineCheck() 
        {
            IgnitionSequenceStart(launchTime).
        }
    }
    OutInfo2().

    until countdown >= 0.1
    {
        OutMsg("COUNTDOWN T" + round(countdown, 1)).
        wait 0.01.
    }
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
    local engList to GetEnginesByStage(stage:number - 1).
    for eng in GetEngines("Active")
    {
        engList:add(eng).
    }
    for eng in engList
    {
        if not (eng:ConsumedResources:Keys:Contains("Solid Fuel"))
        {
            return true.
        } 
    }
    OutMsg("All-solid first stage detected, disabling throttle-up").
    return false.
}

// Engine startup sequence
global function IgnitionSequenceStart
{
    parameter cdEngStart.

    set tVal to 0.25.
    lock throttle to tVal.
    local engList to GetEngines("active").
    for eng in GetEnginesByStage(stage:number - 1)
    {
        engList:add(eng).
    }

    //stage.

    local ts_engThrAbort to time:seconds + 5.
    
    local thrObj to GetEnginesPerfData()["thr"].
    local curThr to thrObj["cur"].
    local avlThr to thrObj["avlPres"].

    until tVal >= .99 and (max(curThr, 0.001) / max(avlThr, 0.001)) > 0.995
    {

        set thrObj to GetEnginesPerfData(engList, "1010")["thr"].
        set curThr to thrObj["cur"].
        set avlThr to thrObj["avlPres"].

        if time:seconds > ts_engThrAbort
        {
            set g_abort to true.
            PadAbort(). // TODO - for now, will crash, and that's acceptable
        }
        else
        {
            OutMsg("COUNTDOWN T" + round(time:seconds - cdEngStart, 1)).
            OutInfo("Engine Start Sequence").
            OutInfo2("Stage Thrust: {0}kn / {1}kn  ({2}%)":format( round(thrObj["cur"], 2), round(thrObj["avlPres"], 2), round(Max(0.0000000001, (thrObj["cur"]) / max(0.0000000001, thrObj["avlPres"])) * 100, 2))).
            set tVal to tVal + 0.05.
            wait 0.01.
        }
    }

    set tVal to 1.
}

// Drops umbilicals and retracts swing arms
global function LaunchArmRetract
{
    local animateMod to list().  // Main list
    
    for m in ship:modulesNamed("ModuleAnimateGenericExtra")  // Swing arms that are not crew arms
    {
        if not m:part:name:matchesPattern("(CrewArm|Crane|DamperArm)") animateMod:add(m).
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
                if m:part:tag:length = 0 
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
                else if m:part:tag = "left"
                {
                    DoAction(m, "toggle arm left").
                }
                else if m:part:tag = "right"
                {
                    DoAction(m, "toggle arm right").
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
            if not DoEvent(m, "retract arm")
            {
                if not DoEvent(m, "retract crew arm")
                {
                    if not DoEvent(m, "raise walkway")
                    {
                        if m:part:tag = "extendOkay" 
                        {
                            DoAction(m, "toggle crew arm", true).
                        }
                    }
                }
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

    local les to "".
    local lesDC to "".
    local lesList to list().

    for p in ship:parts
    {
        if p:name = "LaunchEscapeSystem" or p:name = "restock-engine-les-2" or p:tag = "LES"
        {
            lesList:add(p).
            set les to p.
        }
    }

    local lesDCList to ship:partsTagged("LES.DC").

    set lesDC to choose les if lesDCList:length = 0 else lesDCList.


    if lesDCList:length > 0
    {
        lesList:add(ship:partsTagged("LES.DC")[0]).
        set lesDC to ship:partsTagged("LES.DC")[0].
    }
    
    if les <> ""
    {
        when ship:altitude >= jettAlt then
        {
            les:activate.
            wait 0.01. 
            if les:thrust > 0 
            {
                if lesDC:hasModule("ModuleDecouple")
                {
                    lesDC:getModule("ModuleDecouple"):doEvent("Decouple").
                    OutInfo("LES Tower Jettisoned").
                    g_abortGroup:remove("LES").
                    g_abortGroup:remove("LESDecouple").
                }
                else
                {
                    OutTee("CAUTION: LES Jettison failure!", 0, 1).
                }
            }
            else
            {
                OutInfo("CAUTION: LES Engines Failed").
            }
        }
    }
}

// Retracts the special Titan / Saturn V parts
global function RetractAuxPadStructures
{
    parameter partList, 
              waitUntilComplete is false.

    local modLex to lex().
    local ceList to list().
    local armList to list().
    local craneList to list().
    local auxPartRegex to list("AM.MLP.*(CrewElevatorGemini){1}", "AM.MLP.(Saturn){1}.*(Crane){1}", "AM.MLP.(Saturn){1}.*(DamperArm){1}", "SoyuzLaunchBaseGantry", "SoyuzLaunchBaseArm").

    for p in partList
    {
        local pModList to p:modules.
        from { local i to 0.} until i = pModList:length step { set i to i + 1.} do
        {
            local m to p:getModuleByIndex(i).
            if m:name:matchesPattern("ModuleAnimateGeneric")
            {
                if m:hasAction("toggle front white panels") set modLex[m] to list("retract front white panels", "toggle front white panels").
                else if m:hasAction("toggle tower") set modLex[m] to list("lower tower", "toggle tower").
                else if m:hasAction("toggle crane rotation") set modLex[m] to list("rotate crane", "toggle crane location").
                else if m:hasAction("toggle damper arm") set modLex[m] to list("raise arm", "toggle damper arm").
                else if m:hasEvent("retract gantry arms") set modLex[m] to list("retract gantry arms", "toggle gantry arms").
                else if m:hasEvent("retract arm") set modLex[m] to list("retract arm", "toggle arm").
            }
        }
    }

    MovePadAuxGear(modLex).
    wait 0.01.

    if waitUntilComplete
    {
        OutMsg("Waiting for Aux Pad Gear Retraction").
        local moveFlag to false.
        if modLex:keys:length > 0 
        {
            until false
            {
                for m in modLex:keys
                {
                    if m:hasField("Status")
                    {
                        if m:getField("Status"):contains("Moving") 
                        {
                            set moveFlag to true.
                        }
                        else 
                        {
                            set moveFlag to false.
                        }
                    }
                }
                if not moveFlag break.
            }
        }
    }
}

// MovePadAuxGear :: 
local function MovePadAuxGear 
{
    parameter _modLex.

    if _modLex:keys:length > 0 
    {
        for m in _modLex:keys
        {
            DoEvent(m, _modLex[m][0]).// DoAction(m, _modLex[m][1], true).
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

    local lesDCFlag to true.

    for p in ship:parts
    {
        if p:name = "LaunchEscapeSystem" or p:name = "restock-engine-les-2" or p:tag:contains("LES")
        {
            if p:tag = "LES" 
            {
                LESList:add(p).
                if lesDCFlag
                {
                    set g_abortGroup["LESDecoupler"] to p:getModule("ModuleDecouple").    
                }
            }
            else if p:tag = "LES.Decoupler"
            {
                set g_abortGroup["LESDecoupler"] to p:getModule("ModuleDecouple").
                set lesDCFlag to false.
            }
            else 
            {
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