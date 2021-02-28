@lazyGlobal off.

runOncePath("0:/lib/lib_vessel").

// Functions for orbital maneuvers

// dV calculations
global function mnv_dv_prograde
{
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    // Calculate semi-major axis
    local tSma to tgtAlt + mnvBody:radius.
    local sSma to stAlt  + mnvBody:radius.

    return sqrt(mnvBody:mu / tSma) * (1 - sqrt((2 * sSma) / (tSma + sSma))).
}

global function mnv_dv_retrograde
{
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    // Calculate semi-major axis
    local tSma to tgtAlt + mnvBody:radius.
    local sSma to stAlt  + mnvBody:radius.

    return sqrt(mnvBody:mu / sSMA) * ( sqrt( (2 * tSMA) / (sSMA + tSMA)) - 1).
}

// Duration to burn dv. Takes in the total needed dv to burn, and returns the 
// total burn duration across all stages as an object, with the "all" summed key
global function mnv_burn_dur
{
    parameter dvNeeded.
   
    // Get the amount of dv in each stage
    local dvStgObj  to mnv_burn_stages(dvNeeded).
    local dvBurnObj to mnv_burn_dur_stage(dvStgObj).
    return dvBurnObj["all"].
}

// Given an object containing a list of stages and dv to burn for each stage,
// returns an object of burn duration by stage, plus an "all" key with the 
// total duration of the burn across all stages
global function mnv_burn_dur_stage
{
    parameter dvStgObj.

    local dvBurnObj to lex().
    set dvBurnObj["all"] to 0.

    for key in dvStgObj:keys
    {
        local exhVel    to ves_stage_exh_vel(key).
        local stgThr    to ves_stage_thrust(key).
        local vesMass   to ves_mass_at_stage(key).

        local burnDur   to ((vesMass * exhVel) / stgThr) * (1 - (constant:e ^ (-1 * (dvStgObj[key] / exhVel)))).
        set dvBurnObj[key] to burnDur.
        set dvBurnObj["all"] to dvBurnObj["all"] + burnDur.
    }
    return dvBurnObj.
}


// Calculates stages used for a given dv burn. Assumes that the burn starts 
// with the current stage. Returns a lexicon containing stage num and dv per 
// stage. Used with the mnv_burn_dur function
global function mnv_burn_stages
{
    parameter dvNeeded.

    local dvStgObj to lex().
    set dvNeeded to abs(dvNeeded).

    // If we need more dV than the vessel has, throw an exception.
    if dvNeeded > ship:deltaV:current {
        hudText("Not enough deltaV on vessel!", 10, 2, 24, red, false).
        return 1 / 0.
    }

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dvNeeded <= 0 step { set stg to stg - 1.} do
    {
        local dvStg to ship:stageDeltaV(stg):current.
        if dvStg > 0 
        {
            if dvNeeded <= dvStg
            {
                set dvStgObj[stg] to dvNeeded.
                break.
            }
            else 
            {
                set dvStgObj[stg] to dvStg.
                set dvNeeded to dvNeeded - dvStg.
            }
        }
    }
    return dvStgObj.
}


// Set pitch by deviation from a reference pitch to ensure gradual gravity turns and proper
// pitch during maneuvers
global function mnv_pitch_ang
{
    parameter tgtAlt.
    
    // Calculates needed pitch angle to track towards target altitude
    if verticalSpeed > 0 
    {
        return min(0, -(90 * (1 - (ship:altitude) / (tgtAlt)))).
    }

    else
    {
        return max(0, 90 * ( 1 - (ship:altitude) / (tgtAlt))).
    }
}.