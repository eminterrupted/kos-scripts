@lazyGlobal off. 

parameter tAp to 1067581,
          tPe to 1067581,
          tInc to 0,
          tGTurnAlt to 60000,
          rVal to 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_node").

runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/data/ship/lib_mass").

runOncePath("0:/lib/part/lib_fairing").
runOncePath("0:/lib/part/lib_antenna").

runOncePath("0:/kslib/library/lib_l_az_calc").

//
//Vars
local launchLog is lex(
    "launchStart", 0
    ,"lngStart", 0
    ,"launchDur", 0
    ,"launchDegrees", 0
    ).

local launchPlannerPath is "archive:/data/launchWindowPlanners/lwp_" + ship:name:split(" ")[0] + ".json".
local lp is get_launch_planner().

local runmode to stateObj["runmode"].

local maxAcc to 30.
local maxQ to 0.10.

local launchObj to lex(
    "accPid", setup_acc_pid(maxAcc)
    ,"azObj", l_az_calc_init(tAp, tInc)
    ,"gtStart", 1000
    ,"maxAcc", maxAcc
    ,"maxQ", maxQ
    ,"qPid", setup_q_pid(maxQ)
    ,"runmode", runmode
    ,"rVal", rVal
    ,"tAp", tAp
    ,"tGTurnAlt", tGTurnAlt
    ,"tGEndPitch", 0
    ,"tInc", tInc
    ,"tPe",tPe
).


// -- Begin -- //
if lp["lastLaunched"] <> "" {
    set target to lp["lastLaunched"].

    local window to get_launch_window().
    
    mlp_gen_on().

    wait_until_launch_window(window).
}


// Log the current time and longitude in the launchLog
set launchLog["launchStart"] to time:seconds.
set launchLog["lngStart"] to choose ship:longitude if ship:longitude >= 0 else 360 + ship:longitude.

// Main launch script
main().


//Functions
// Main loop
local function main {
    
    clearScreen.
    out_msg("Executing launch sequence()").
    launch_sequence(launchObj).

    out_msg("Executing circularization_burn()").
    exec_circ_burn("ap", launchObj["tAp"]).

    out_msg("Logging launch to launchLog").
    write_launch_log().

    out_msg("Executing prep_for_orbit()").
    set runmode to prep_for_orbit().
    
    out_msg("Executing cleanup()").
    set runmode to cleanup().

    out_msg("Executing end_main()").
    set runmode to end_main().

    clearScreen.
}


// Here we see if we are the first relay to launch
// If we are, log the time. If the time file for the craft name 
// already exists, then wait until the next available window
// and record our own launch time before launching.
local function get_launch_planner {

    if exists(launchPlannerPath) {
        return readJson(launchPlannerPath).
    } else {
        return lex(
            "plan", "KerbRelSat 200"
            ,"lastLaunched", ""
            ,"totalLaunches", 0
            ,"totalCount", 4
            ,"orbitAltitude", tAp
            ,"orbitPeriod", 2 * constant:pi * sqrt(( tAp + ship:body:radius)^3 / (constant:g * ship:body:mass))
            ,"launchLog", lex(
                "launchStart", 0
                ,"lngStart", 0
                ,"launchDur", 0
                ,"launchDegrees", 0
            )
        ).
    }
}

local function get_launch_window {
    
    update_display().

    local idealDegrees is 90.
    local secsPerDegree is lp["orbitPeriod"] / 360.
    local targetDegreesOnLaunch is (lp["launchLog"]:launchDur / target:obt:period) * 360.
    local degreesAhead is idealDegrees - targetDegreesOnLaunch + lp["launchLog"]:launchDegrees.

    return list(degreesAhead + 30, secsPerDegree).
}

local function degrees_behind_target {

    local curLong to choose ship:longitude if ship:longitude >= 0 else (360 + ship:longitude).
    local tgtLong to choose target:longitude if target:longitude >= 0 else (360 + target:longitude).

    if tgtLong < curLong set tgtLong to tgtLong + 360.

    return tgtLong - curLong.
}

local function wait_until_launch_window {
    parameter _window.

    local desiredDegreesBehind is _window[0].
    local secsPerDegree is _window[1].

    local currentLong to choose ship:longitude if ship:longitude >= 0 else (360 + ship:longitude).

    until round(degrees_behind_target, 2) = round(desiredDegreesBehind - (12 * (secsPerDegree / 360)), 2) {
        update_display().

        set currentLong to choose ship:longitude if ship:longitude >= 0 else (360 + ship:longitude).

        out_msg("Current target position: " + degrees_behind_target()).
        out_msg("Needed target position : " + desiredDegreesBehind).
    }

    if warp > 0 kuniverse:timewarp:cancelwarp().
    print "                                                                " at (2, 8).
}

// Logs the launch 
local function write_launch_log {
    set launchLog["launchDur"] to time:seconds - launchLog["launchStart"].
    set launchLog["launchDegrees"] to choose ship:longitude - launchLog["lngStart"] if ship:longitude >= 0 else (360 + ship:longitude) - launchLog["lngStart"].
    set lp["launchLog"] to launchLog.
    set lp["lastLaunched"] to ship:name.
    set lp["totalLaunches"] to lp["totalLaunches"] + 1.

    writeJson(lp, launchPlannerPath).
}



local function prep_for_orbit {
    logStr("Preparing for orbit").

    logStr("Opening bay doors").
    bays on.

    wait 2.
    
    logStr("Deploying solar panels").
    panels on.

    logStr("Verifying connection to KSC").
    if not addons:rt:hasKscConnection(ship) activate_omni(ship:partsTaggedPattern("comm.omni")[0]).
    logStr("Orbtial configuration set").

    update_display().

    set runmode to 28.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}



local function cleanup {
    logStr("Unlocking controls").
    unlock steering.
    unlock throttle.

    update_display().

    set runmode to 30.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function end_main {
    logStr("Preparing for mission script handoff").
        
    from { local n is 10.} until n <= 0 step { set n to n - 1.} do {
        update_display().
        disp_timer(n).
    }

    disp_clear_block_all().
    logStr("Ship ready for mission script").
    
    set runmode to 99.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}