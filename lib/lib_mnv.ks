@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
//#include "0:/lib/lib_vessel"

//#region -- deltaV Calculations
// dV calculations
global function mnv_dv_hohmann
{
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    // Calculate semi-major axis
    local tgtSMA to tgtAlt + mnvBody:radius.
    local stSMA  to stAlt  + mnvBody:radius.

    local dv1 to sqrt(mnvBody:mu / stSMA) * (sqrt((2 * tgtSMA) / (tgtSMA + stSMA)) - 1).
    local dv2 to sqrt(mnvBody:mu / tgtSMA) * (1 - sqrt((2 * stSMA) / (stSMA + tgtSMA))).
    return list(dv1, dv2).
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
        hudText("dV Needed: " + dvNeeded + ". Not enough deltaV on vessel!", 10, 2, 24, red, false).
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
//#endregion

//#region -- Duration (time to burn) calculations
// Total duration to burn provided dv
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

        local stgBurDur     to ((vesMass * exhVel) / stgThr) * (1 - (constant:e ^ (-1 * (dvStgObj[key] / exhVel)))).
        set dvBurnObj[key]  to stgBurDur.
        set dvBurnObj["all"] to dvBurnObj["all"] + stgBurDur.
    }
    return dvBurnObj.
}
//#endregion

//#region -- Actions (executing maneuvers)
//Simple burn emnv_exec_circ_burn facing either prograde or retrograde
global function mnv_exec_circ_burn
{
    parameter burnEta, 
              burnDuration, 
              burnPro.

    local meco to burnEta + burnDuration.

    lock burnHeading to choose compass_for(ship, ship:prograde) if burnPro else compass_for(ship, ship:retrograde).
    local rVal       to choose 180 if ship:crew():length > 0 else 0.
    local tVal       to 0.

    lock steering    to heading(burnHeading, 0, rVal).
    lock throttle    to tVal.

    if time:seconds <= burnEta - 30 
    {
        hudtext("Press 0 to warp to burnEta - 30s", 10, 2, 20, yellow, false).
        on ag10 
        {
            warpTo(burnEta - 30).
            wait until kuniverse:timewarp:issettled.
            ag10 off.
        }
    }
   
    until time:seconds >= burnEta
    {
        mnv_burn_disp(burnEta, burnDuration).
        wait 0.01.
    }

    set tVal to 1.
    disp_msg("Executing burn").

    until time:seconds >= meco
    {
        mnv_burn_disp(burnEta, meco - time:seconds).
        wait 0.01.
    }
    set tVal to 0.

    disp_msg("Maneuver complete!").
    wait 5.
    clearScreen.
}
//#endregion

//#region -- Local helpers
local function mnv_burn_disp
{
    parameter burnEta, burnDur.

    disp_info("Burn ETA: " + round(time:seconds - burnEta, 1)).
    disp_info2("Burn duration: " + round(burnDur, 1)). 
    disp_telemetry().
}
//#endregion