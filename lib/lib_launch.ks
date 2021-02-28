@lazyGlobal off.

// Functions used only during a launch

//Set pitch by deviation from a reference pitch to ensure more gradual gravity turns and course corrections
global function launch_ang_for_alt
{
    parameter turnAlt,
              startAlt,
              endPitch.
    
    // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
    local pitch     to max(endPitch, 90 * (1 - (ship:altitude - startAlt) / (turnAlt))). 
    // Controls how far from prograde we can deviate to avoid oversteer
    local pg        to choose ship:srfPrograde:vector if ship:body:atm:altitudepressure(ship:altitude) > 0.0001 else ship:prograde:vector.
    local pgPitch   to 90 - vang(ship:up:vector, pg).
    // Calculate the effective pitch
    local effPitch  to max(pgPitch - 2.5, min(pitch, pgPitch + 2.5)).
    return effPitch.
}.

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