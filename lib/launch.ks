@lazyGlobal off.

//-- Dependencies
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

//-- Functions

//#region -- Ascent functions
// Set pitch by deviation from a reference pitch
global function launch_ang_for_alt
{
    parameter turnAlt,
              startAlt,
              endPitch,
              pitchLim is 4.
    
    // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
    local pitch     to max(endPitch, 90 * (1 - ((ship:altitude - startAlt) / (turnAlt - startAlt)))). 
    // local pg to ship:srfprograde:vector.

    local pg        to choose ship:srfPrograde:vector if ship:body:atm:altitudepressure(ship:altitude) * constant:atmtokpa > 0.0050 else ship:prograde:vector.
    local pgPitch   to 90 - vang(ship:up:vector, pg).
    set pitchLim    to choose pitchLim if ship:body:atm:altitudePressure(ship:altitude) * constant:atmtokpa > 0.0040 else pitchLim * 5.
    // Calculate the effective pitch with a 5 degree limiter
    local effPitch  to max(pgPitch - pitchLim, min(pitch, pgPitch + pitchLim)).
    return effPitch.
}.
//#endregion

//#region -- Countdown and Launch pad functions
// Launch countdown
global function launch_countdown
{
    parameter s is 15.

    local tVal to 0.
    lock throttle to tVal.

    local launchTime to time:seconds + s.
    lock countdown to time:seconds - launchTime. 
    
    disp_info("Countdown initiated").

    launch_pad_fallback_partial().
    launch_pad_crew_arm_retract().
    until countdown >= -10 
    {
        disp_msg("COUNTDOWN: " + round(countdown, 2)).
    }    

    until countdown >= -8
    {
        disp_msg("COUNTDOWN T" + round(countdown, 2)).
        wait 0.05.
    }
    launch_pad_rofi().

    until countdown >= -6
    {
        disp_msg("COUNTDOWN T" + round(countdown, 2)).
        wait 0.05.
    }
    launch_pad_gen(false).

    until countdown >= -1.5
    {
        disp_msg("COUNTDOWN T" + round(countdown, 2)).
        wait 0.05.
    }

    if ship:status = "PRELAUNCH" 
    {
        launch_engine_start(launchTime).
        set tVal to 1.
    }
    disp_info2().
    launch_pad_arms_retract().
    launch_pad_fallback_full().
    until countdown >= 0
    {
        disp_msg("COUNTDOWN T" + round(countdown, 2)).
        wait 0.05.
    }
    unlock countdown.
}

// Engine startup sequence
global function launch_engine_start
{
    parameter cdEngStart.

    local tVal to 0.25.
    lock throttle to tVal.
    
    stage.
    until tVal >= .99
    {
        disp_msg("COUNTDOWN T" + round(time:seconds - cdEngStart, 1)).
        disp_info("Engine Start Sequence").
        disp_info2("Throttle: " + round(tVal * 100) + "% ").
        set tVal to tVal + 0.0275.
        wait 0.025.
    }
}

// Drops umbilicals and retracts swing arms
global function launch_pad_arms_retract
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
                util_do_event(m, "drop umbilical").
            }
            else if m:part:name:contains("swingarm")
            {
                if m:hasEvent("toggle") util_do_event(m, "toggle").
                if m:hasEvent("retract arm right") util_do_event(m, "retract arm right").
                if m:hasEvent("retract arm") util_do_event(m, "retract arm").
            }
        }
    }
}

// Retracts a crew arm
global function launch_pad_crew_arm_retract
{
    local animateMod to list().  // Main list
    
    for m in ship:modulesNamed("ModuleAnimateGenericExtra")  // Swing arms that are not crew arms
    {
        if m:part:name:contains("CrewArm") animateMod:add(m).
    }
        
    if animateMod:length > 0
    {
        disp_info("Retracting crew arm").
        for m in animateMod
        {
            if m:hasEvent("retract arm") util_do_event(m, "retract arm").
            if m:hasEvent("retract crew arm") util_do_event(m, "retract crew arm").
        }
    }
}

// Fallback tower
global function launch_pad_fallback_partial
{
    local animateMod to ship:modulesNamed("ModuleAnimateGenericExtra").
    local clampEvent to "open upper clamp".
    local towerEvent to "partial retract tower step 1".

    if animateMod:length > 0 
    {
        for m in animateMod
        {
            if m:hasEvent(clampEvent) 
            {
                util_do_event(m, clampEvent).
                wait until m:getField("status") = "Locked".
            }
            else if m:hasEvent(towerEvent) util_do_event(m, towerEvent).
        }
    }
}

global function launch_pad_fallback_full
{
    local animateMod to ship:modulesNamed("ModuleAnimateGenericExtra").
    local towerEvent to "full retract tower step 2".

    if animateMod:length > 0 
    {
        for m in animateMod
        {
            if m:hasEvent(towerEvent) 
            {
                util_do_event(m, towerEvent).
                break.
            }
        }
    }
}

// Toggles launchpad generator
global function launch_pad_gen
{
    parameter powerOn.

    local genList   to ship:modulesNamed("ModuleGenerator").
    for g in genList
    {
        if powerOn 
        {
            disp_info("Vehicle on external power").
            util_do_event(g, "activate generator").
        }
        else 
        {
            disp_info("Vehicle on internal power").
            util_do_event(g, "shutdown generator").
        }
    }
}

// Hold downs retract
global function launch_pad_holdowns_retract
{
    local animateMod to ship:modulesNamed("ModuleAnimateGenericExtra").
    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("hold")
            {
                util_do_event(m, "retract arm").
            }
            else if m:part:name:contains("SaturnLauncherTSM")
            {
                util_do_event(m, "retract arm").   
            }
        }
    }
}

// ROFI sparklers
global function launch_pad_rofi
{
    local rofiList to ship:partsNamed("AM_MLP_GeneralROFI").

    if rofiList:length > 0 
    {
        disp_info("Igniting ROFI system").
        for r in rofiList 
        {
            r:activate.
        }
    }
}
//#endregion