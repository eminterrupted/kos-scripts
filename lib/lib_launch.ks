@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").

local mlp to false.

if ship:partsTaggedPattern("mlp.base"):length > 0 
{
    runOncePath("0:/lib/part/lib_launchpad").
    set mlp to true.
}

//Main launch sequencer
global function launch_sequence 
{

    parameter lObj.
                
    local runmode is 0.

    clearScreen.
    print "MSG: Executing preLaunch()                   " at (2, 7).
    preLaunch().

    print "MSG: Executing launch()                      " at (2, 7).
    launch().

    print "MSG: Executing clear_tower()                 " at (2, 7).
    clear_tower().

    print "MSG: Executing roll_program()                " at (2, 7).
    roll_program(lObj).

    print "MSG: Executing vertical_ascent()             " at (2, 7).
    set lObj["gtStart"] to vertical_ascent(lObj).

    print "MSG: Executing gravity turn()                " at (2, 7).
    gravity_turn(lObj).

    print "MSG: Executing slow_burn_to_apo()            " at (2, 7).
    slow_burn_to_apo(lObj).

    print "MSG: Executing meco()                        " at (2, 7).
    meco(lObj).

    if ship:altitude < 70000 
    {
        print "MSG: Executing coast_to_space()              " at (2, 7).
        coast_to_space(lObj).
    }

    return runmode.
}


//Fairings
global function arm_proc_fairings 
{
    parameter pAlt,
              base.

    logStr("arm_proc_fairings").

    local cList is base:children.
    
    when ship:altitude > pAlt then 
    {
        for f in cList 
        {
            if f:tag:contains("pl.pf.fairing") jettison_fairing(f).
        }
        logStr("Fairings jettison").
    }
}

global function arm_stock_fairings 
{
    parameter pAlt,
              base.

    logStr("arm_stock_fairings").

    when ship:altitude > pAlt then 
    {
        jettison_fairing(base).
        logStr("Fairings jettison").
    }
}


// Launch a vessel with a countdown timer
global function launch_vessel 
{
    parameter countdown is 10, 
              engStart is 2.2.

    logStr("launch_vessel").

    clearScreen.
    global cd is countdown.

    lock steering to up - r(0,0,90).

    local fallback is false.
    local holddown is false.
    local launchFlag to choose true if ship:status = "PRELAUNCH" else false.
    local swingarm is false.
    local umbilical is false.

    for p in ship:partsTaggedPattern("mlp") 
    {
        if p:tag:matchesPattern("fallback") set fallback to true.
        else if p:tag:matchesPattern("holddown") set holddown to true.
        else if p:tag:matchesPattern("swingarm") set swingarm to true.
        else if p:tag:matchesPattern("umbilical") set umbilical to true.
    }

    //Setup the launch triggers. 
    if mlp 
    {
        when cd <= countdown * 0.95 then 
        {
            mlp_retract_crewarm().
            logStr("Crew arm retract").
        }

        when cd <= countdown * 0.75 then 
        {
            if fallback 
            {
                mlp_fallback_open_clamp().
                logStr("Fallback clamp open").
            }
        }

        when cd <= countdown * 0.5 then 
        {
            mlp_fuel_off().
            logStr("Fueling complete").
        }

        when cd <= countdown * 0.45 then 
        {
            mlp_gen_off(). 
            logStr("Vehicle on internal power").
        }

        when cd <= countdown * 0.4 then 
        {
            if fallback 
            {
                mlp_fallback_partial().
                logStr("Fallback tower partial retract").
            }
        }

        when cd <= 0.8 then 
        {
            if fallback 
            {
                mlp_fallback_full().
                logStr("Fallback tower full retract").
            }

            if swingarm 
            {
                mlp_retract_swingarm().
                logStr("Swing arms detached").
            }
        }

        when cd <= 0.2 then 
        {
            if umbilical 
            {
                mlp_drop_umbilical().
                logStr("Umbilicals detached").
            }
        }

        when cd <= 0.1 then 
        {
            if holddown 
            {
                mlp_retract_holddown().
                logStr("Holddown retracted").
            }
        }
    }

    if launchFlag 
    {
        when cd <= engStart then 
        {
            logStr("Engine start sequence").
            engine_start_sequence().
        }
    }
    

    logStr("Beginning launch countdown").
    until cd <= 0 
    {
        disp_main().
        wait 0.1.
        set cd to cd - 0.1.
    }

    lock throttle to 1.
    stage.
    unset cd.
    clearScreen.
}

local function engine_start_sequence 
{
    
    local tSpool to 0.
    lock throttle to tSpool.

    stage.
    from { local t to 0.} until t >= 0.15 step { set t to t + 0.01.} do 
    {
        disp_main().
        set tSpool to t.
        set cd to cd - 0.015.
    }

    from { local t to 0.16.} until t >= 1 step { set t to t + 0.02.} do 
    {
        disp_main().
        lock throttle to tSpool.
        set tSpool to min(1, t).
        set cd to cd - 0.015.
    }

    lock throttle to 1.
}


//Set pitch by deviation from a reference pitch to ensure more gradual gravity turns and course corrections
global function get_la_for_alt 
{

    parameter rPitch, 
              tAlt,
              sAlt is 1000.
    
    local tPitch is 0.

    if rPitch < 0 
    {
        set tPitch to min( rPitch, -(90 * ( 1 - (ship:altitude - sAlt) / (tAlt)))).
    }

    else if rPitch >= 0 
    {
        set tPitch to max( rPitch, 90 * ( 1 - (ship:altitude - sAlt) / (tAlt))).
    }
    
    local pg is choose ship:srfPrograde:vector if ship:body:atm:altitudepressure(ship:altitude) > 0.0001 else ship:prograde:vector.
    local pgPitch is 90 - vang(ship:up:vector, pg).
    local effPitch is max(pgPitch - 5, min(tPitch, pgPitch + 5)).
    
    return effPitch.
}.


global function get_circ_burn_pitch 
{
    local obtPitch is 90 - vang(ship:up:vector, ship:prograde:vector).
    return obtPitch * -1.
}


local function preLaunch 
{
    local runmode is rm(0).
    logStr("[Runmode " + runmode + "]: Preparing for launch").
    
    disp_main().
}


local function launch 
{
    local runmode to rm(5).
    logStr("[Runmode " + runmode + "]: Begin launch procedure").

    if ship:partsTaggedPattern("pl.st.fairing"):length > 0 
    {
        arm_stock_fairings(72500, ship:partsTaggedPattern("pl.st.fairing")[0]).
    } 
    else if ship:partsTaggedPattern("pl.pf.base"):length > 0 
    {
        arm_proc_fairings(72500, ship:partsTaggedPattern("pl.pf.base")[0]).
    }

    launch_vessel(10).
    
    local tVal to 1.
    lock throttle to tVal.

    update_display().
}    


local function clear_tower 
{
    local runmode to rm(10).
    logStr("[Runmode " + runmode + "]: Liftoff!").
    
    local sVal to heading(90, 90, -90).
    local tVal to 1.

    lock steering to sVal.
    lock throttle to tVal.

    //Wait until tower is effectively cleared
    until alt:radar >= 100 
    {   
        update_display().
    }
    
    logStr("Tower cleared").
    update_display().
}
    

local function roll_program 
{
    parameter lObj.

    local runmode to rm(15).
    logStr("[Runmode " + runmode + "]: Roll program").

    local sVal to heading(l_az_calc(lObj["azObj"]), 90, lObj["rVal"]).
    lock steering to sVal.

    local tVal to 1.
    lock throttle to tVal.
    
    update_display().
}


local function vertical_ascent 
{
    parameter lObj.

    local runmode to rm(20).
    logStr("[Runmode " + runmode + "]: Vertical ascent").
    
    local sVal to heading(l_az_calc(lObj["azObj"]), 90, lObj["rVal"]).
    lock steering to sVal.
    
    local tVal to 1.
    lock throttle to tVal.

    //Setup staging triggers
    staging_triggers().

    //Ascent loop
    until ship:verticalSpeed >= 100 or ship:altitude >= 1000 
    {
        update_display().
    }
    
    return ship:altitude.
}

local function gravity_turn 
{
    parameter lObj.
           
    local runmode to rm(25).
    logStr("[Runmode " + runmode + "]: Pitch program").
    
    local sVal to heading(l_az_calc(lObj["azObj"]), get_la_for_alt(lObj["tGEndPitch"], lObj["tGTurnAlt"], lObj["gtStart"]), lObj["rVal"]).
    local tVal to 1.

    lock steering to sVal.
    lock throttle to tVal.

    local acc to 0.
    local accPid to setup_acc_pid(lObj["maxAcc"]).
    local qPid to setup_q_pid(lObj["maxQ"]).

    when ship:q >= lObj["maxQ"] then logStr("Approaching Max-Q").
    when acc >= lObj["maxAcc"] then logStr("Throttling back at maximum acceleration").

    //Gravity turn loop
    until ship:apoapsis >= lObj["tAp"] * 0.995 
    {
        set sVal to heading(l_az_calc(lObj["azObj"]), get_la_for_alt(lObj["tGEndPitch"], lObj["tGTurnAlt"], lObj["gtStart"]), lObj["rVal"]).
        set acc to ship:maxThrust / ship:mass.

        //Check for throttle conditions, otherwise keep it at 100%
        if ship:q >= lObj["maxQ"] 
        {
            set tVal to max(0, min(1, 1 + qPid:update(time:seconds, ship:q))). 
        } 
        else if acc >= lObj["maxAcc"] - 5 
        {
            set tVal to max(0, min(1, 1 + accPid:update(time:seconds, acc))).
        } 
        else 
        {
            set tVal to 1.
        }
        update_display().
    }
    
    set runmode to 30.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.   
}

local function slow_burn_to_apo 
{
    parameter lObj. 

    local runmode to rm(30).
    logStr("[Runmode " + runmode + "]: Throttling back near apoapsis. [CurAlt:" + round(ship:altitude) + "][Apo:" + round(ship:apoapsis) + "]").

    local sVal to heading(l_az_calc(lObj["azObj"]), get_la_for_alt(lObj["tGEndPitch"], lObj["tGTurnAlt"], lObj["gtStart"]), lObj["rVal"]).
    lock steering to sVal.

    local tVal to 1.
    lock throttle to tVal.

    until ship:apoapsis >= lObj["tAp"] 
    {
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, lObj["rVal"]).
        set tval to 0.35.

        update_display().
    }
}


local function meco 
{
    parameter lObj.

    local runmode to rm(35).
    logStr("[Runmode " + runmode + "]: MECO").

    local sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, lObj["rVal"]).
    lock steering to sVal.

    local tVal to 0.
    lock throttle to tVal.

    update_display().
}


local function coast_to_space 
{
    parameter lObj.
    
    local runmode to rm(40).
    logStr("[Runmode " + runmode + "]: Coast phase").

    local sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, lObj["rVal"]).
    lock steering to sVal.

    local tVal to 0.
    lock throttle to tVal.

    until ship:altitude >= body:atm:height 
    {
        set sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, lObj["rVal"]).

        if ship:apoapsis >= lObj["tAp"] 
        {
            set tVal to 0.
        } 
        else 
        {
            set tVal to 0.25.
        }

        update_display().
    }
    
    logStr("Reached space").
}