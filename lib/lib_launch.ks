@lazyGlobal off.

//-- Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").

//-- Functions

//#region -- Ascent functions
// Set pitch by deviation from a reference pitch
global function launch_ang_for_alt
{
    parameter turnAlt,
              startAlt,
              endPitch.
    
    // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
    local pitch     to max(endPitch, 90 * (1 - ((ship:altitude - startAlt) / (turnAlt - startAlt)))). 

    local pg        to choose ship:srfPrograde:vector if ship:body:atm:altitudepressure(ship:altitude) > 0.0025 else ship:prograde:vector.
    local pgPitch   to 90 - vang(ship:up:vector, pg).

    // Calculate the effective pitch with a 5 degree limiter
    local effPitch  to max(pgPitch - 5, min(pitch, pgPitch + 5)).
    return effPitch.
}.
//#endregion

//#region -- Countdown and Launch pad functions
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

// Toggles launchpad generator
global function launch_pad_gen
{
    parameter powerOn.

    local genList   to ship:modulesNamed("ModuleGenerator").
    for g in genList
    {
        if powerOn 
        {
            util_do_event(g, "activate generator").
        }
        else 
        {
            util_do_event(g, "shutdown generator").
        }
    }
}

// Drops umbilicals and retracts swing arms randomly within 1s
global function launch_pad_arms_retract
{
    local animateMod to ship:modulesNamed("ModuleAnimateGeneric").
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
                util_do_event(m, "toggle").
                util_do_event(m, "retract arm right").
            }
        }
    }
}

// Hold downs retract
global function launch_pad_holdowns_retract
{
    local animateMod to ship:modulesNamed("ModuleAnimateGeneric").
    if animateMod:length > 0
    {
        for m in animateMod
        {
            if m:part:name:contains("hold")
            {
                util_do_event(m, "retract arm").
            }
        }
    }
}
//#endregion