@lazyGlobal off.

set terminal:width to 90.
set terminal:height to 50.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").

//For custom strings to be added by scripts. 
//  Schema is lexicon(["x,y"]screen location key, list(["str"]string,[[var]value, etc...])). 
//  Example: lex("2,6",list("EXAMPLE:     ", exampleVar, "    "))
global dObj is lexicon().

global function disp_main {
    print "Kerbal's First Launch Program                     v0.1b" at (0,2).
    print "=======================================================" at (0,3).
    print "UTC: " at (42,4).
    print time:clock at (47,4).
    print "VESSEL:        " + ship:name                             at (2,5).
    print "MET:           " + format_timestamp(missionTime) + "    "            at (2,6).
    print "kOS IPU CFG:   " + config:ipu at (30,6).
    print "BODY:          " + body:name + "     "               at (2,7).
    print "STATUS:        " + status + "              "             at (30,7).
}


global function disp_vessel_data {
    print "PROGRAM:" at (2,10).        print stateObj["program"] + "  " at (17,10).
        print "RUNMODE:" at (30,10). print stateObj["runmode"] at (45,10).
    print "MASS:" at (02,11).           print round(ship:mass, 2) + "     " at (17,11).
        print "STAGE NUMBER:  " + stage:number + "    " at (30,11).
}


global function disp_launch_telemetry {
    parameter pMaxAlt is 0.

    print "ALTITUDE:      " + round(ship:altitude) + "    "     at (2,13).
    print "MAX ALTITUDE:  " + round(pMaxAlt) + "    "           at (2,14).
    print "DYNPRESS:      " + round(ship:q, 5) + "    "         at (30,13).
    print "ATMPRESS:      " + round(body:atm:altitudepressure(ship:altitude), 5) + "      " at (30,14).

    print "APOAPSIS:      " + round(ship:apoapsis) + "    "            at (2,16).
        print "TIME TO AP:    " + format_timestamp(eta:apoapsis) + "    " at (30,16).
    print "PERIAPSIS:     " + round(ship:periapsis) + "    "           at (2,17).
        print "TIME TO PE:    " + format_timestamp(eta:periapsis) + "    " at (30,17).
    print "ECCENTRICTY:   " + round(ship:orbit:eccentricity, 5) at (2,18).
        print "ORBITAL PER:   " + format_timestamp(ship:orbit:period) + "    " at (30,18).
    print "ORBITAL VEL:   " + round(ship:velocity:orbit:mag) + "    " at (2,19).
    print "VELOCITY:      " + round(ship:airspeed) + "    "     at (30,19).
    
    print "THROTTLE:      " + round(throttle * 100, 2) + "%   "    at (2,21).
        print "THRUST:        " + round(get_thrust(), 2) + "     " at (30,21).
    print "ISP:           " + round(get_avail_isp_for_alt(ship:altitude, stage:number), 2) + "  " at (2,22).
        print "TWR:           " + round(get_twr_for_modes_stage_alt("mass","cur",stage:number, ship:altitude), 2) + "      "  at (30,22).
    //
    //print round(get_twr_for_modes_stage_alt("mass","avail", stage:number, ship:altitude), 2) + " " at (48,20).
}


global function clear_sec_data_fields {
    print "                                                                      " at (0,24).
    print "                                                                      " at (0,25).
    print "                                                                      " at (0,26).
    print "                                                                      " at (0,27).
    print "                                                                      " at (0,28).
    print "                                                                      " at (0,29).
}


global function disp_burn_data {

    parameter pObj.

    print "BURN DATA" at (2,24).
    print "---------" at (2,25).
    if pObj:haskey("dV")        print "DELTA-V:       " + round(pObj["dV"], 1) + " m/s  "   at (2,26).
    if pObj:haskey("burnDur")   print "BURN DURATION: " + round(pObj["burnDur"]) + " s  "    at (2,27).
    if pObj:haskey("burnEta")   print "BURN START:    " + format_timestamp(max(0, pObj["burnEta"] - time:seconds)) + "  "    at (30,26).
    if pObj:haskey("burnEnd")   print "BURN END:      " + format_timestamp(max(0, pObj["burnEnd"] - time:seconds)) + "  "    at (30,27).
}


global function disp_countdown {
    print "COUNTDOWN: T - " + dObj["countdown"] at (2,10).
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