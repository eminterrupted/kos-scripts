@lazyGlobal off.

set terminal:width to 80.
set terminal:height to 65.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_pid.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").

//For custom strings to be added by scripts. 
//  Schema is lexicon(["x,y"]screen location key, list(["str"]string,[[var]value, etc...])). 
//  Example: lex("2,6",list("EXAMPLE:     ", exampleVar, "    "))
global dObj is lexicon().

global vSync is 0.
local col1 is 2.
local col2 is col1 + 15.  
local col3 is 40.
local col4 is col3 + 15.

local pos0 is lexicon("v",2,"h1",col1,"h2",col3).
local posA is lexicon("v",12,"h1",col1,"h2",col2).
local posB is lexicon("v",12,"h1",col3,"h2",col4).
local posC is lexicon("v",26,"h1",col1,"h2",col2).
local posD is lexicon("v",26,"h1",col3,"h2",col4).
local posE is lexicon("v",40,"h1",col1,"h2",col2,"h3",col3,"h4",col4).
local posF is lexicon("v",40,"h1",col1,"h2",col2,"h3",col3,"h4",col4).

local clr is "                                                                      ".

// when vSync >= 80 then {
//     init_vsync().
//     preserve.
// }

global function disp_launch_main {
    
    local pos is pos0.
    
    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "KUSP Mission Controller                                     KMC v0.03c" at (0,vSync).
    print "======================================================================" at (0,vNext).
    print "UTC: " at (h1 + 55,vNext).
    print time:clock at (h1 + 60,vSync).
    vNext().
    vNext().
    print "MISSION:       " + ship:name                             at (h1,vNext).
    print "BODY:          " + body:name + "     "               at (h2,vSync).
    print "MET:           " + format_timestamp(missionTime) + "    "            at (h1,vNext).
    print "STATUS:        " + status + "              "             at (h2,vSync).
    print "PROGRAM:       " + stateObj["program"] + "  " at (h1,vNext).
    print "RUNMODE:       " + stateObj["runmode"] + "  " at (h2,vSync).
}


global function disp_test_main {
    
    parameter p. 

    local pos is pos0.
    
    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "KUSP Test Stand Controller                                       v0.01" at (0,vSync).
    print "======================================================================" at (0,vNext).
    print "UTC: " at (h1 + 55,vNext).
    print time:clock at (h1 + 60,vSync).
    vNext().
    vNext().
    print "MISSION:       " + ship:name                             at (h1,vNext).
    print "MET:           " + format_timestamp(missionTime) + "    "            at (h2,vSync).
    vNext().
    print "TEST PART:     " + p:title + "                          " at (h1,vNext).
}

local function vNext {
    set vSync to vSync + 1.
    return vSync.
}

local function init_vsync {
    set vSync to 0.
}

global function disp_orbital_data {
    parameter pos is posA.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "ORBITAL DATA                 " at (h1,vSync).
    print "------------                 " at (h1,vNext).
    print "APOAPSIS:      " + round(ship:apoapsis) + "    "            at (h1,vNext).
    print "PERIAPSIS:     " + round(ship:periapsis) + "    "           at (h1,vNext).
    print "ECCENTRICTY:   " + round(ship:orbit:eccentricity, 5) at (h1,vNext).
    print "INCLINATION:   " + round(ship:orbit:inclination, 5) at (h1, vNext).
    print "ORBITAL PER:   " + format_timestamp(ship:orbit:period) + "    " at (h1,vNext).
    print "TIME TO AP:    " + format_timestamp(eta:apoapsis) + "    " at (h1,vNext).
    print "TIME TO PE:    " + format_timestamp(eta:periapsis) + "    " at (h1,vNext).
    print "ORBITAL VEL:   " + round(ship:velocity:orbit:mag) + "    " at (h1,vNext).
}

global function disp_launch_telemetry {
    parameter pMaxAlt is 0,
              pos is posB.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "LAUNCH TELEMETRY             " at (h1,vSync).
    print "----------------             " at (h1,vNext).
    print "ALTITUDE:      " + round(ship:altitude) + "    "     at (h1,vNext).
    print "MAX ALTITUDE:  " + round(pMaxAlt) + "    "           at (h1,vNext).
    print "ATMPRESS:      " + round(body:atm:altitudepressure(ship:altitude), 5) + "      " at (h1,vNext).
    print "DYNPRESS:      " + round(ship:q, 5) + "    "         at (h1,vNext).
}


global function disp_engine_perf_data {
    
    parameter pos is posC.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "ENGINE PERFORMANCE           " at (h1,vSync).
    print "------------------           " at (h1,vNext).
    print "THROTTLE:      " + round(throttle * 100, 2) + "%   "    at (h1,vNext).
    print "THRUST:        " + round(get_thrust(), 2) + "     " at (h1,vNext).
    print "ISP:           " + round(get_avail_isp(), 2) + "      " at (h1,vNext).
    print "TWR:           " + round(get_twr_for_modes_stage_alt("mass","cur",stage:number, ship:altitude), 2) + "      "  at (h1,vNext).
    print "MASS:" at (h1,vNext).           print round(ship:mass, 2) + "     " at (h2,vSync).
    //
    //print round(get_twr_for_modes_stage_alt("mass","avail", stage:number, ship:altitude), 2) + " " at (48,20).
}


global function clear_sec_data_fields {

    set vSync to 24. 

    print clr at (0,vSync).
    print clr at (0,vNext).
    print clr at (0,vNext).
    print clr at (0,vNext).
    print clr at (0,vNext).
    print clr at (0,vNext).
}


global function clear_disp_block {
    
    parameter pos.

    if pos = "a" set pos to posA.
    else if pos = "b" set pos to posB.
    else if pos = "c" set pos to posC.
    else if pos = "d" set pos to posD.
    else if pos = "e" set pos to posE.
    else if pos = "f" set pos to posF.
    
    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print clr at (h1,vSync).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
    print clr at (h1,vNext).
}


global function disp_burn_data {

    parameter pObj.

    local pos is posD.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "BURN DATA" at (h1,vSync).
    print "---------" at (h1,vNext).
    if pObj:haskey("dV")        print "DELTA-V:       " + round(pObj["dV"], 1) + " m/s  "   at (h1,vNext).
    if pObj:haskey("burnDur")   print "BURN DURATION: " + round(pObj["burnDur"]) + " s  "    at (h1,vNext).
    if pObj:haskey("burnEta")   print "BURN START:    " + format_timestamp(max(0, pObj["burnEta"] - time:seconds)) + "  "    at (h1,vNext).
    if pObj:haskey("burnEnd")   print "BURN END:      " + format_timestamp(max(0, pObj["burnEnd"] - time:seconds)) + "  "    at (h1,vNext).
}


global function disp_deploy {

    parameter pDeploy.

    local pos is posE.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "PAYLOAD DEPLOYMENT           " at (h1,vSync).
    print "------------------           " at (h1,vNext).
    print "ETA:" at (h1,vNext). print format_timestamp(pDeploy - time:seconds) + "                                    " at (h2,vSync). 
}


global function disp_countdown {
    print "COUNTDOWN: T - " + dObj["countdown"] at (2,11).
}

global function out_host {

    parameter pObj.

    for key in pObj:keys {
        local pos to key:split(",").
        print pObj[key] at(pos[0]:tonumber,pos[1]:tonumber). 
    }
}

//Takes dObj and outputs what is inside. Clears dobj after display to avoid stale elements
global function disp_dobj {

    for key in dObj:keys {
        local pos to key:split(",").
        print dObj[key]:join(" ") at(pos[0]:tonumber,pos[1]:tonumber). 
    }

    dObj:clear().
}


global function disp_pid_data {

    local pos is posD.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    if not (defined tPid) setup_tpid(0.15).
    local pidOutput is tPid:output.

    print "PID LOOP DATA" at (h1,vSync).
    print "-------------" at (h1,vNext).
    print "INPUT VAR:     " + round(ship:q, 5) + "          " at (h1,vNext).
    print "SETPOINT:      " + round(tPid:setpoint, 5) + "          " at (h1, vNext). 
    print "ERROR:         " + round(tPid:error, 5) + "          "    at (h1, vNext).
    print "OUTPUT VALUE:  " + round(pidOutput, 5) + "          "    at (h1,vNext).
    print "AGG TVAL:      " + round((1 + pidOutput) * 100, 1)+ "%       " at (h1,vNext).
    
}



global function disp_scan_status {
    
    parameter pData.

    local pos is posE.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h3"].

    print "SCANSAT STATUS           " at (h1,vSync).
    print "--------------           " at (h1,vNext).
    for field in pData:keys {
        print field:tostring:toupper + ":" at (h1, vNext). 
        print pData[field] at (h2, vSync).
    }
}



global function disp_launch_params {
    local pos is posE.

    parameter tApo, tPe, tInc, gravTurnAlt, refPitch.

    set vSync to pos["v"].
    local h1 is pos["h1"].
    local h2 is pos["h2"].

    print "LAUNCH PARAMETERS" at (h1,vSync).
    print "-----------------" at (h1,vNext).
    print "TAPO:            " + tApo at (h1,vNext).
    print "TPE:             " + tPe at (h1,vNext).
    print "TINC:            " + tInc at (h1,vNext).
    print "GRAVTURNALT:     " + gravTurnAlt at (h1,vNext).
    print "REFPITCH:        " + refPitch at (h1,vNext).
}