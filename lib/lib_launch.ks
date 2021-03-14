@lazyGlobal off.

//-- Dependency for azimuth calc
runOncePath("0:/kslib/lib_l_az_calc").

// Functions used only during a launch

// Set pitch by deviation from a reference pitch to ensure gradual gravity turns and proper
// pitch during maneuvers
global function launch_ang_for_alt
{
    parameter turnAlt,
              startAlt,
              endPitch.
    
    // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
    local pitch     to max(endPitch, 90 * (1 - (ship:altitude - startAlt) / (turnAlt))). 

    local pg        to ship:srfPrograde:vector.
    local pgPitch   to 90 - vang(ship:up:vector, pg).

    // Calculate the effective pitch with a 2.5 degree limiter
    local effPitch  to max(pgPitch - 2.5, min(pitch, pgPitch + 2.5)).
    return effPitch.
}.

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
        set tVal to tVal + 0.025.
        wait 0.025.
    }
}

// Toggles launchpad generator
global function launch_pad_gen
{
    parameter powerOn.

    local genList   to ship:modulesNamed("ModuleGenerator").
    local genOn     to "activate generator".
    local genOff    to "shutdown generator".
    for g in genList
    {
        if powerOn 
        {
            if g:hasEvent(genOn) g:doEvent(genOn).
        }
        else 
        {
            if g:hasEvent(genOff) g:doEvent(genOff). 
        }
    }
}

// Drops umbilicals and retracts swing arms randomly within 1s
global function launch_pad_arms_retract
{

    local animateMod to ship:modulesNamed("ModuleAnimateGeneric").
    local umbEvent   to "drop umbilical".
    local armEvent   to "retract arm right".
    local togEvent   to "toggle".

    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("umbilical")
            {
                if m:hasEvent(umbEvent) m:doEvent(umbEvent).
            }
            else if m:part:name:contains("swingarm")
            {
                if m:hasEvent(togEvent) m:doEvent(togEvent).
                if m:hasEvent(armEvent) m:doEvent(armEvent).
            }
        }
    }
}

// Hold downs retract
global function launch_pad_holdowns_retract
{
    local animateMod to ship:modulesNamed("ModuleAnimateGeneric").
    local hdEvent    to "retract arm".

    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("hold")
            {
                if m:hasEvent(hdEvent) m:doEvent(hdEvent).
            }
        }
    }
}