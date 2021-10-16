@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//
local line to 0.

//-- Functions --//

//-- Display Utilities
// Clears a line assuming a 60 char display
global function clr
{
    parameter clrLine.
    print "                                                            " at (0, clrLine).
}

global function clr_disp
{
    set line to 10.
    until line = terminal:height - 1
    {
        clr(line).
        set line to line + 1.
    }
}

// Local function for incrementing ln
global function cr
{
    set line to line + 1.
    return line.
}

// Formats a timestamp into one of a few format strings
global function disp_format_time
{
    parameter ts,
              format is "ts".

    set ts to abs(ts).
    local tsMod to 0.

    local y  to 0.
    local d  to 0.
    local h  to 0.
    local m  to 0.
    local s  to 0.
    local ms to 0.
    
    local secsPerDay  to kuniverse:hoursperday * 3600.
    local secsPerYear to kerbin:orbit:period.

    if ts >= secsPerYear
    {
        set tsMod to mod(ts, secsPerYear).
        set y to ts - tsMod.
        set y to y / secsPerYear.
        set ts to tsMod.
    }
    if ts >= secsPerDay
    {
        set tsMod to mod(ts, secsPerDay).
        set d to ts - tsMod.
        set d to d / secsPerDay.
        set ts to tsMod.
    }
    if ts >= 3600
    {
        set tsMod to mod(ts, 3600).
        set h to ts - tsMod.
        set h to h / 3600.
        set ts to tsMod.
    }
    if ts >= 60
    {
        set tsMod to mod(ts, 60).
        set m to ts - tsMod.
        set m to m / 60.
        set ts to tsMod.
    }
    if ts >= 1 
    {
        set tsMod to mod(ts, 1).
        set s to ts - tsMod.
        set ts to tsMod.
    }
    if ts > 0 
    {
        set ms to round(ts, 2).
    }

    if format = "ts"
    {
        local tsY  to choose y  if y  >= 10 else choose "0" + y  if y  >= 0 else "00".
        local tsD  to choose d  if d  >= 10 else choose "0" + d  if d  >= 0 else "00".
        local tsH  to choose h  if h  >= 10 else choose "0" + h  if h  >= 0 else "00".
        local tsM  to choose m  if m  >= 10 else choose "0" + m  if m  >= 0 else "00".
        local tsS  to choose s  if s  >= 10 else choose "0" + s  if s  >= 0 else "00".
        local tsMS to "00".
        if ms > 0
        {
            set tsMS to choose ms if ms >= 10 else "0" + ms.
            if tsMS:contains(".") set tsMS to tsMs:toString:split(".")[1].
        }
        
        return tsY + "y, " + tsD + "d T" + tsH + ":" + tsM + ":" + tsS + "." + tsMS.
    }
    else if format = "dateTime"
    {
        local dtY  to choose y  if y >= 1000 else choose "0" + y if y >= 100 else choose "00" + y if y >= 10 else "000" + y.
        local dtD  to choose d  if d  >= 10 else choose "0" + d  if d  >= 0 else "00".
        local dtH  to choose h  if h  >= 10 else choose "0" + h  if h  >= 0 else "00".
        local dtM  to choose m  if m  >= 10 else choose "0" + m  if m  >= 0 else "00".
        local dtS  to choose s  if s  >= 10 else choose "0" + s  if s  >= 0 else "00".
        local dtMS to choose ms if ms >= .1 else choose "0" + ms if ms >= .01 else "00".
        if ms > 0 
        {
            if dtMS:typename = "Scalar" set dtMS to dtMS:toString.
            if dtMS:contains(".") set dtMS to dtMS:toString:split(".")[1].
        }
        
        return dtY + "-" + dtD + "T" + dtH + ":" + dtM + ":" + dtS + "." + dtMS.
    }
}

// Print a string to the hud with errorLevel
global function disp_hud 
{
    parameter str,
              errLvl is 0,
              screenTime is 15.

    local color to green.
    if errLvl = 1 set color to yellow.
    if errLvl = 2 set color to red.

    hudtext(str, screenTime, 2, 20, color, false).          
}

// Print a string to the info line
global function disp_info
{
    parameter str is "".
    //print "INFO : " + str + "          " at (0, 7).
    clr(7).
    print str at (0, 7).
}

global function disp_info2
{
    parameter str is "".
    //print "INFO : " + str + "          " at (0, 8).
    clr(8).
    print str at (0, 8).
}

// Print a string to the msg line
global function disp_msg
{
    parameter str is "".
    //print "MSG  : " + str + "          " at (0, 6).
    clr(6).    
    print str at (0, 6).
}

// Prints to both hud and msg line
global function disp_tee
{
    parameter str is "",
              errLvl is 0,
              screenTime is 15.

    disp_msg(str).
    disp_hud(str, errLvl, screenTime).
}

// Sets up the terminal
global function disp_terminal
{
    set terminal:height to 50.
    set terminal:width to 60.
    core:doAction("open terminal", true).
}

//-- Main Displays
// A display for airplane flights
global function disp_avionics
{
    set line to 10.
    
    print "AVIONICS" at (0, line).
    print "---------" at (0, cr()).
    print "ALTITUDE         : " + round(ship:altitude)              + "m      " at (0, cr()).
    cr().
    print "AIRSPEED         : " + round(ship:airspeed, 1)              + "m/s    " at (0, cr()).
    print "VERT SPEED       : " + round(ship:verticalspeed, 1)         + "m/s    " at (0, cr()).
    print "GROUND SPEED     : " + round(ship:groundspeed, 1)           + "m/s    " at (0, cr()).
    cr().
    print "THROTTLE         : " + round(throttle * 100)             + "%      " at (0, cr()).
    print "AVAIL THRUST     : " + round(ship:availablethrust, 2)    + "kN     " at (0, cr()).
    cr().
    print "PRESSURE (KPA)   : " + round(body:atm:altitudePressure(ship:altitude) * constant:atmtokpa, 5) + "   " at (0, cr()).
}

// Displays the launch plan prior to launching
global function disp_launch_plan
{
    parameter launchPlan.
    
    set line to 10.

    print "LAUNCH PLAN OVERVIEW" at (0, line).
    print "--------------------" at (0, cr()).
    cr().
    print "APOAPSIS            : " + launchPlan:tgtAp at (0, cr()).
    print "PERIAPSIS           : " + launchPlan:tgtPe at (0, cr()).
    cr().
    print "INCLINATION         : " + launchPlan:tgtInc at (0, cr()).
    print "LAUNCH LAN          : " + launchPlan:tgtLAN at (0, cr()).
    cr().
    print "WAIT FOR LAN WINDOW : " + launchPlan:waitForLAN at (0, cr()).
}

global function disp_launch_window
{
    parameter tgtLAN, tgtEffectiveLAN, launchTime.

    set line to 10.

    print "LAUNCH WINDOW" at (0, line).
    print "-------------" at (0, cr()).
    cr().
    if hasTarget 
    print "TARGET           : " + target at (0, cr()).
    print "TARGET LAN       : " + tgtLAN at (0, cr()).
    print "EFFECTIVE LAN    : " + tgtEffectiveLAN at (0, cr()).
    cr().
    print "CURRENT LAN      : " + round(ship:orbit:lan, 5) at (0, cr()).
    print "TIME TO LAUNCH   : " + disp_format_time(time:seconds - launchTime) at (0, cr()).
}


// A display header for mission control
global function disp_main
{
    parameter plan is scriptPath():name,
              showTerminal is true.
    set line to 1.
    if showTerminal disp_terminal().

    print "Mission Controller v2.0.1" at (0, line).
    print "=========================" at (0, cr()).
    print "MISSION : " + ship:name    at (0, 3).
    print "PLAN    : " + plan         at (0, 4).
}

// Mnv details
global function disp_mnv_burn
{
    parameter burnEta, dvToGo is 0, burnDur is 0.

    disp_msg("MNV DELTAV TO GO: " + round(dvToGo, 2)). 
    if burnEta <= 0 
    {
        set burnEta to abs(burnEta).
        if burnEta > 60
        {
            set burnEta to disp_format_time(burnEta, "datetime").
        }
        else
        {
            set burnEta to round(burnEta, 2).
        }
        disp_info("BURN ETA        : " + burnEta).
        disp_info2("BURN DURATION   : " + round(burnDur, 2) + "s     ").
    }
    else
    {
        disp_info("BURN DURATION   : " + round(burnDur, 2) + "s     ").
        disp_info2().
    }
}


// Results of a maneuver optimization
global function disp_mnv_score 
{
    parameter tgtVal,
              tgtBody,
              intercept,
              result,
              score.

    set line to 10.
    
    print "NODE OPTIMIZATION"               at (0, line).
    print "-----------------"               at (0, cr()).
    print "TARGET BODY   : " + tgtBody      at (0, cr()).
    print "TARGET VAL    : " + tgtVal       at (0, cr()).
    print "RESULT VAL    : " + result       at (0, cr()).
    cr().
    print "SCORE         : " + score        at (0, cr()).
    print "INTERCEPT     : " + intercept    at (0, cr()).
}

// Simple orbital telemetry
global function disp_orbit
{
    set line to 10.
    
    print "ORBIT" at (0, line).
    print "---------" at (0, cr()).
    print "BODY         : " + ship:body:name        + "       " at (0, cr()).
    print "ALTITUDE     : " + round(ship:altitude)  + "m      " at (0, cr()).
    print "APOAPSIS     : " + round(ship:apoapsis)  + "m      " at (0, cr()).
    print "PERIAPSIS    : " + round(ship:periapsis) + "m      " at (0, cr()).
}

// Impact telemetry
global function disp_impact
{
    parameter tti is 0.

    print "LANDING TELEMETRY" at (0, 10).
    print "-----------------" at (0, 11).
    print "BODY           : " + ship:body:name   + "      " at (0, 12).
    print "ALTITUDE       : " + round(ship:altitude)    + "m     " at (0, 13).
    print "RADAR ALT      : " + round(ship:altitude - ship:geoposition:terrainheight)        + "m     " at (0, 14).
    print "VERTICAL SPD   : " + round(ship:verticalspeed, 2) + "m/s   " at (0, 15).
    print "TIME TO IMPACT : " + round(tti, 2)              + "s   " at (0, 16).
}


// Simple landing telemetry
global function disp_landing
{
    parameter tti is 0, 
              burnDur is 0.

    print "LANDING TELEMETRY" at (0, 10).
    print "-----------------" at (0, 11).
    print "BODY           : " + ship:body:name   + "      " at (0, 12).
    print "ALTITUDE       : " + round(ship:altitude)    + "m     " at (0, 13).
    print "RADAR ALT      : " + round(ship:altitude - ship:geoposition:terrainheight)        + "m     " at (0, 14).
    print "SURFACE SPD    : " + round(ship:groundspeed, 2) + "m/s   " at (0, 15).
    print "VERTICAL SPD   : " + round(ship:verticalspeed, 2) + "m/s   " at (0, 16).

    print "THROTTLE       : " + round(throttle * 100)            + "%  " at (0, 18).
    print "TIME TO IMPACT : " + round(tti, 2)              + "s   " at (0, 19).
    print "BURN DURATION  : " + round(burnDur, 2)          + "s   " at (0, 20).
}

// Generic API for printing a telemetry section, takes a list of header strings / values
global function disp_generic
{
    parameter dispList, stLine is 22.

    set line to stLine.
    
    from { local idx is 0.} until idx >= dispList:length step { set idx to idx + 1.} do 
    {
        if idx = 0 
        {
            print dispList[idx] at (0, line).
            print "--------------" at (0, cr()).
            cr().
        }
        else
        {
            print dispList[idx]:toUpper at (0, line).
            print ":     " at (16, line).
            set idx to idx + 1.
            print dispList[idx] at (18, line).
            cr().
        }
    }
}

// Provides a readout of pid values and output against tgt val
global function disp_pid_readout
{
    parameter pid, tgtVal is 0, curVal is 0.

     print "TGTVAL: " + round(tgtVal, 5) + "     " at (0, 25).
     print "CURVAL: " + round(curVal, 5) + "      " at (0, 26).
     print "ERROR : " + round(curVal - tgtVal, 5) + "     " at (0, 27).

     print "PIDOUT: " + round(pid:output, 2) + "     " at (0, 29).

     print "P TERM: " + round(pid:pterm, 5) + "     " at (0, 31).
     print "I TERM: " + round(pid:iterm, 5) + "     " at (0, 32).
     print "D TERM: " + round(pid:dterm, 5) + "     " at (0, 33).
}

// General telemetry for flight
global function disp_telemetry
{
    print "TELEMETRY" at (0, 10).
    print "---------" at (0, 11).
    print "ALTITUDE         : " + round(ship:altitude)              + "m      " at (0, 12).
    print "APOAPSIS         : " + round(ship:apoapsis)              + "m      " at (0, 13).
    print "PERIAPSIS        : " + round(ship:periapsis)             + "m      " at (0, 14).

    print "THROTTLE         : " + round(throttle * 100)             + "%      " at (0, 16).
    print "AVAIL THRUST     : " + round(ship:availablethrust, 2)    + "kN     " at (0, 17).
    print "MAX ACCELERATION : " + round(ship:availableThrust / ship:mass, 2) + "m/s   " at (0, 18).

    if body:atm:exists and ship:altitude <= 85000
    {
        print "SURFACE SPEED    : " + round(ship:velocity:surface:mag)  + "m/s   " at (0, 20).
        print "PRESSURE (ATM)   : " + round(body:atm:altitudePressure(ship:altitude), 7) + "   " at (0, 21).
        print "PRESSURE (KPA)   : " + round(body:atm:altitudePressure(ship:altitude) * constant:atmtokpa, 7) + "   " at (0, 22).
        print "Q                : " + round(ship:q, 7) + "     " at (0, 23).
    }
    else
    {
        print "ORBITAL SPEED    : " + round(ship:velocity:orbit:mag)    + "m/s   " at (0, 20).
        print "                                               " at (0, 21).
        print "                                               " at (0, 22).
        print "                                               " at (0, 23).
    }
}

// Resource transfer readout
global function disp_res_transfer
{
    parameter res, srcElement, tgtElement, amt, srcRes, srcResFill, tgtRes, tgtResFill.

    if amt < 0 set amt to srcRes.

    print "RESOURCE TRANSFER" at (0, 10).
    print "-----------------" at (0, 11).
    print "RESOURCE             : " + res at (0, 12).
    print "AMOUNT TO TRANSFER   : " + round(amt) + "     " at (0, 13).
    print " " at (0, 14).
    print "SOURCE ELEMENT       : " + srcElement:name at (0, 15).
    print "RESOURCE REMAINING   : " + round(srcRes) + "     " at (0, 16).
    print "FILL (%)             : " + round(srcResFill * 100) + "     " at (0, 17).
    print " " at (0, 18).
    print "TARGET ELEMENT       : " + tgtElement:name at (0, 19).
    print "RESOURCE REMAINING   : " + round(tgtRes) + "     " at (0, 20).
    print "FILL (%)             : " + round(tgtResFill * 100) + "     " at (0, 21).
}