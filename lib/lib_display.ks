@lazyGlobal off.

if terminal:width < 65 set terminal:width to 65.
if terminal:height < 50 set terminal:height to 55.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_pid.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").

//For custom strings to be added by scripts. 
//  Schema is lex(["x,y"]screen location key, list(["str"]string,[[var]value, etc...])). 
//  Example: lex("2,6",list("EXAMPLE:     ", exampleVar, "    "))

local dispObj is lex().

local clrWide is "                                                                      ".
local clr is "                                        ".

local col1 is 2.
local col2 is col1 + 14.  
local col3 is 38.
local col4 is col3 + 14.

local h1 to 0.
local h2 is 0.
local h3 is 0.
local h4 is 0.

local posmain is lex("id", "posmain", "v", 0, "h1", col1, "h2", col2, "h3", col3, "h4", col4).
local pos_a is lex("id", "pos_a", "v", 10, "h1", col1, "h2", col2).
local pos_b is lex("id","pos_b", "v", 10, "h1", col3, "h2", col4).
local pos_c is lex("id", "pos_c", "v", 26, "h1", col1, "h2", col2).
local pos_d is lex("id", "pos_d", "v", 26, "h1", col3, "h2", col4).
//local pos_e is lex("id", "pos_e", "v", 42, "h1", col1, "h2", col2).
//local pos_f is lex("id","pos_f", "v", 42, "h1", col3, "h2", col4).
// local pos_g is lex("id", "pos_g", "v", 58, "h1", col1, "h2", col2).
// local pos_h is lex("id", "pos_h", "v", 58, "h1", col3, "h2", col4).
local posw_x is lex("id", "posw_x", "v", 26, "h1", col1, "h2", col2, "h3", col3, "h4", col4).
local posw_y is lex("id", "posw_y", "v", 38, "h1", col1, "h2", col2, "h3", col3, "h4", col4).
local posw_z is lex("id", "posw_z", "v", 50, "h1", col1, "h2", col2, "h3", col3, "h4", col4).

local posObj is lex(
                "posmain", posmain 
                ,"pos_a", pos_a 
                ,"pos_b", pos_b 
                ,"pos_c", pos_c 
                ,"pos_d", pos_d
                // ,"pos_e", pos_e
                // ,"pos_f", pos_f
                // ,"pos_g", pos_g 
                // ,"pos_h", pos_h 
                ,"posw_x", posw_x
                ,"posw_y", posw_y
                ,"posw_z", posw_z
                ).
                
local posState is lex(
                //"posmain", false
                "pos_a", false 
                ,"pos_b", false
                ,"pos_c", false 
                ,"pos_d", false 
                // ,"pos_e", false 
                // ,"pos_f", false 
                // ,"pos_g", false 
                // ,"pos_h", false 
                ,"posw_x", false
                ,"posw_y", false
                ).


global ln is 0.

//Common strings
local divDbl to "=============================================================".


//-- Main Headers
global function disp_main {
    local pos is posmain.
    //local stateObj is init_state_obj().

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].
    set h3 to pos["h3"].
    set h4 to pos["h4"].

    print "KUSP Mission Controller v0.03c" at (2,ln).
    print "UTC:" at (h4 - 2,ln).
    print time:clock at (h4 + 3,ln).
    print divDbl at (2,cr).
    cr.
    print "MISSION:       " + ship:name + "    " at (h1,cr).
        print "MET:           " + format_timestamp(missionTime) + "    " at (h3,ln).
    print "BODY:          " + body:name + "     " at (h1,cr).
        print "STATUS:        " + status + "     "             at (h3,ln).
    print "PROGRAM:       " + stateObj["program"] + "   " at (h1,cr).
        print "RUNMODE:       " + stateObj["runmode"] + "   " at (h3,ln).
    cr.
    if defined cd print "COUNTDOWN:     " + round(cd, 1) + "  " at (h1, cr).
    else print clr at (h1, ln).
}

global function disp_test_main {
    parameter p,
              t is -1,
              cd is 0.

    local pos is posmain.
    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].
    set h3 to pos["h3"].
    set h4 to pos["h4"].

    print "KUSP Test Stand Controller v0.01" at (2,ln).
    print "UTC:" at (h4 - 2,ln).
    print time:clock at (h4 + 3,ln).
    print divDbl at (2,cr).
    cr.
    cr.
    print "TEST PART:  " + p:title:padright(55 - p:title:length) at (h1,cr).
    print "PART NAME:  " + p:name:padRight(55 - p:name:length) at (h1,cr).
    cr. 
    if t = -1 print "TEST STARTING IN: " + cd + clr at (2,cr).
    else if t = -2 print "TEST COMPLETE!" + clrWide at (2,cr).
    else {
        print "TEST TIMER: " + format_timestamp(t) + "  " at (h1,cr).
        if mod(round(t), 2) = 0 print "** TEST IN PROGRESS **" at (h3,ln).
        else if mod(round(t), 2) = 1 print clr at (h3,ln).
    }
}


//-- Panels
global function disp_obt_data {
    
    local pos is "assign".
    if dispObj:haskey("obt") set pos to disp_get_pos_obj(dispObj["obt"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["obt"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "ORBITAL DATA                 " at (h1,ln).
    print "------------                 " at (h1,cr).
    print "APOAPSIS:      " + round(ship:apoapsis) + "      "       at (h1,cr).
    print "PERIAPSIS:     " + round(ship:periapsis) + "      "      at (h1,cr).
    print "ECCENTRICTY:   " + round(ship:obt:eccentricity, 5) at (h1,cr).
    cr.
    print "INCLINATION:   " + round(ship:obt:inclination, 5) at (h1, cr).
    print "LONG ASC NODE: " + round(ship:obt:lan, 5) + "    " at (h1, cr).
    print "ARG OF PE:     " + round(ship:obt:argumentofperiapsis, 5) + "    " at (h1,cr).
    cr.
    print "TIME TO AP:    " + format_timestamp(eta:apoapsis) + "    " at (h1,cr).
    print "TIME TO PE:    " + format_timestamp(eta:periapsis) + "    " at (h1,cr).
    print "ORBITAL PER:   " + format_timestamp(ship:obt:period) + "    " at (h1,cr).
}

global function disp_tel {
    
    local pos is "assign".
    if dispObj:haskey("l_tel") set pos to disp_get_pos_obj(dispObj["l_tel"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["l_tel"] to pos["id"].
    }
    
    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "TELEMETRY             " at (h1,ln).
    print "---------             " at (h1,cr).
    print "ALT:           " + round(ship:altitude) + "      " at (h1,cr).
    print "OBTVEL:        " + round(ship:velocity:orbit:mag) + "     " at (h1,cr).
    print "SRFVEL:        " + round(ship:velocity:surface:mag) + "     " at (h1, cr).
    cr.
    print "DYNPRESS:      " + round(ship:q, 5) + "     " at (h1,cr).
    print "ATMPRESS:      " + round(body:atm:altitudepressure(ship:altitude), 5) + "     " at (h1, cr).
    cr.
    cr.
    print "BIOME:         " + addons:scansat:currentbiome + "    " at (h1,cr).
    print "LATITUDE:      " +  round(ship:geoposition:lat, 3) + "   " at (h1,cr).
    print "LONGITUDE:     " + round(ship:geoposition:lng, 3) + "   " at (h1,cr).
}


global function disp_eng_perf_data {

    local pos is "assign".
    if dispObj:haskey("eng_perf") set pos to disp_get_pos_obj(dispObj["eng_perf"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["eng_perf"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "ENGINE PERFORMANCE           " at (h1,ln).
    print "------------------           " at (h1,cr).
    print "THROTTLE:      " + round(throttle * 100, 2) + "%     "    at (h1,cr).
    print "THRUST:        " + round(get_thrust(), 2) + "     " at (h1,cr).
    print "ISP:           " + round(get_avail_isp(), 2) + "      " at (h1,cr).
    cr.
    print "TWR:           " + round(get_twr_for_modes_stage_alt("mass","cur",stage:number, ship:altitude), 2) + "      "  at (h1,cr).
    print "MASS:          " +  round(ship:mass, 2) + "     " at (h1,cr).

    return pos.
}


//Burn data - dV, dur, start / end timestamps.
global function disp_burn_data {

    local pos is "assign".
    if dispObj:haskey("burn_data") set pos to disp_get_pos_obj( dispObj["burn_data"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["burn_data"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "BURN DATA" at (h1,ln).
    print "---------" at (h1,cr).
    print "DELTA-V:       " + round(nextNode:deltaV:mag, 1) + " m/s  "   at (h1,cr).
}


global function disp_eta {
    parameter stamp.

    local pos is "assign".
    if dispObj:haskey("eta") set pos to disp_get_pos_obj(dispObj["eta"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["eta"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "ETA" at (h1, ln).
    print "---" at (h1, cr).
    print "TSTAMP ETA:    " + format_timestamp(stamp).
}


//Launch param data - useful for confirming well, launch parameters
global function disp_launch_params {
    parameter tApo, 
              tPe, 
              tInc, 
              gtAlt, 
              gtPitch.

    local pos is "assign".
    if dispObj:haskey("l_param") set pos to disp_get_pos_obj(dispObj["l_param"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["l_param"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "LAUNCH PARAMETERS" at (h1,ln).
    print "-----------------" at (h1,cr).
    print "TAPO:     " at (h1,cr).
    print tApo + "               " at (h2, ln).
    print "TPE:" at (h1,cr).
    print tPe  + "               " at (h2, ln).
    print "TINC:" at (h1,cr).
    print tInc  + "               " at (h2, ln).
    print "gtAlt:" at (h1,cr).
    print gtAlt + "               " at (h2, ln).
    print "gtPitch:" at (h1,cr).
    print gtPitch  + "               " at (h2, ln).
}


//PID controller data
global function disp_pid_data {
    parameter pPid.

    local pos is "assign".
    if dispObj:haskey("pid") set pos to disp_get_pos_obj( dispObj["pid"]).
    else {
        set dispObj["pid"] to disp_get_pos_obj(pos).
        set pos to disp_get_pos_obj(pos).
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "PID LOOP DATA" at (h1,ln).
    print "-------------" at (h1,cr).
    print "INPUT VAR:     " + round(ship:q, 5) + "          " at (h1,cr).
    print "SETPOINT:      " + round(pPid:setpoint, 5) + "          " at (h1, cr). 
    print "ERROR:         " + round(pPid:error, 5) + "          "    at (h1, cr).
    print "OUTPUT VALUE:  " + round(pPid:output, 5) + "          "    at (h1,cr).
}

//Rendezvous
global function disp_rendezvous_data {
    parameter pData.

    local pos is "assign".
    if dispObj:haskey("rendezvous") set pos to disp_get_pos_obj( dispObj["rendezvous"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["rendezvous"] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "RENDEZVOUS" at (h1,ln).
    print "----------" at (h1,cr).
    print "TARGET:        " + pData["tgt"]:name at (h1,cr).
    print "TARGET DIST:   " + round(pData["tgt"]:distance) + "    " at (h1,cr).
    print "TARGET SMA:    " + round(pData["tgt"]:altitude + pData["tgt"]:body:radius) at (h1,cr).
    cr.
    print "PHASE ANG:     " + round(pData["curPhaseAng"], 3) + "  " at (h1,cr).
    print "XFR PHASE ANG: " + round(pData["xfrPhaseAng"], 3) + "  " at (h1,cr).
    print "XFR PHASE ETA: " + format_timestamp(pData["nodeAt"] - time:seconds) + "  " at (h1,cr).
}


//SCANsat data
global function disp_scan_status {
    parameter pData, nScan.

    set nScan to "scan_" + nScan:tostring.

    local pos is "assign_wide".
    if dispObj:haskey(nScan) set pos to disp_get_pos_obj( dispObj[nScan]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj[nScan] to pos["id"].
    }

    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h3"].

    print "SCANSAT STATUS           " at (h1,ln).
    print "--------------           " at (h1,cr).
    for field in pData:keys {
        print field:tostring:toupper + ":" at (h1, cr). 
        print pData[field] at (h2, ln).
    }
}


global function disp_timer {
    parameter pTimer.

    local pos is "assign".
    if dispObj:haskey("timer") set pos to disp_get_pos_obj(dispObj["timer"]).
    else {
        set pos to disp_get_pos_obj(pos).
        set dispObj["timer"] to pos["id"].
    }
    
    set ln to pos["v"].
    set h1 to pos["h1"].
    set h2 to pos["h2"].

    print "TIMER" at (h1,ln).
    print "-----" at (h1,cr).
    print "MARK:" at (h1,cr). 
        print format_timestamp(pTimer - time:seconds) + "           " at (h2,ln). 
}


global function disp_clear_block {
    parameter pos.

    if dispObj:haskey(pos) {
        set pos to disp_get_pos_obj(dispObj[pos]).
    } 

    else return false.

    set ln to pos["v"].
    from { local line is ln.} until line = ln + 13 step { set line to line + 1.} do {
        if pos:hasKey("h1") print clr at (pos["h1"], line).
        if pos:hasKey("h2") print clr at (pos["h2"], line).
        if pos:hasKey("h3") print clr at (pos["h3"], line).
        if pos:hasKey("h4") print clr at (pos["h4"], line).
    }
    set posState[pos["id"]] to false.
}


global function disp_clear_block_all {
    local dispList is list("obt", "l_tel", "eng_perf", "burn_data", "timer", "scan", "rendezvous", "pid", "l_param", "eta").
    for d in dispList {
        disp_clear_block(d).
    }

    clearScreen.
}


global function disp_clear_block_pos {
    parameter pos.

    if dispObj:haskey(pos) set pos to disp_get_pos_obj(pos).
    
    set ln to pos["v"].
    from { local line is ln.} until line = ln + 13 step { set line to line + 1.} do {
        if pos:hasKey("h1") print clr at (pos["h1"], line).
        if pos:hasKey("h2") print clr at (pos["h2"], line).
        if pos:hasKey("h3") print clr at (pos["h3"], line).
        if pos:hasKey("h4") print clr at (pos["h4"], line).
    }
    set posState[pos["id"]] to false.
}


//Inserts a new line into display blocks
local function cr {
    set ln to ln + 1.
    return ln.
}


//Assigns a data section to an open position in the display. pType 0 is standard, pType 1 is wide.
local function disp_get_next_pos {
    parameter pType.

    for key in posState:keys {
        if not posState[key] {
            if pType = 0 {
                if key:startsWith("pos_") {
                    set posState[key] to true.
                    return key.
                }
            }

            else if pType = 1 {
                if key:startsWith("posw_") {
                    set posState[key] to true.
                    return key.
                }
            }
        }
    } 
}


global function disp_get_pos_obj {
    parameter pos.
    
    if pos = "assign" set pos to disp_get_next_pos(0).
    else if pos = "assign_wide" set pos to disp_get_next_pos(1).
    return posObj[pos].
}

//Main launch display updater
global function update_display {
    disp_main().
    disp_obt_data().
    disp_tel().
    if get_active_engs():length > 0 disp_eng_perf_data().
}