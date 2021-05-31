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
local function cr
{
    set line to line + 1.
    return line.
}

// Formats a timestamp into one of a few format strings
global function disp_format_timestamp
{
    parameter ts,
              format is "t".

    local y  to 0.
    local d  to 0.
    local h  to 0.
    local m  to 0.
    local s  to 0.
    
    local secPerDay  to kuniverse:hoursperday * 3600.
    local secPerYear to kerbin:orbit:period.

    if ts >= secPerYear
    {
        set y to round(ts / secPerYear).
        set ts to mod(ts, secPerYear).
    }
    if ts >= secPerDay
    {
        set d to round(ts / secPerDay).
        set ts to mod(ts, secPerDay).
    }
    if ts >= 3600
    {
        set h to round(ts / 3600).
        set ts to mod(ts, 3600).
    }
    if ts >= 60
    {
        set m to round(ts / 60).
        set ts to mod(ts, 60).
    }
    if ts >= 1 
    {
        set s to round(ts).
    }

    if format = "t"
    {
        return "y" + y + " d" + d + " " + h + "h" + m + "m" + s + "s".
    }
    else if format = "utc"
    {
        return "y" + (y + 1) + " d" + (d + 1) + " " + h + ":" + (m - 1) + ":" + s.
    }
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


// A display header for mission control
global function disp_main
{
    parameter plan is scriptPath():name,
              showTerminal is true.
    set line to 1.
    if showTerminal disp_terminal().

    print "Mission Controller v0.02b" at (0, line).
    print "=========================" at (0, cr()).
    print "MISSION : " + ship:name    at (0, 3).
    print "PLAN    : " + plan         at (0, 4).
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
    
    print "NODE OPTIMIZATION"                   at (0, line).
    print "-----------------"                   at (0, cr()).
    print "TARGET BODY   : " + tgtBody          at (0, cr()).
    print "TARGET VAL    : " + tgtVal           at (0, cr()).
    print "RESULT VAL    : " + round(result, 5) at (0, cr()).
    cr().
    print "SCORE         : " + round(score, 5)  at (0, cr()).
    print "INTERCEPT     : " + intercept        at (0, cr()).
}

// Simple orbital telemetry
global function disp_orbit
{
    print "ORBIT" at (0, 10).
    print "---------" at (0, 11).
    print "BODY         : " + ship:body:name        + "       " at (0, 12).
    print "ALTITUDE     : " + round(ship:altitude)  + "m      " at (0, 13).
    print "APOAPSIS     : " + round(ship:apoapsis)  + "m      " at (0, 14).
    print "PERIAPSIS    : " + round(ship:periapsis) + "m      " at (0, 15).
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

    if ship:altitude <= 85000
    {
        print "MAX ACCELERATION : " + round(ship:availableThrust / ship:mass, 2) + "m/s   " at (0, 19).
        print "SURFACE SPEED    : " + round(ship:velocity:surface:mag)  + "m/s   " at (0, 20).
        print "PRESSURE (ATM)   : " + round(body:atm:altitudePressure(ship:altitude), 7) + "   " at (0, 21).
        print "PRESSURE (KPA)   : " + round(body:atm:altitudePressure(ship:altitude) * constant:atmtokpa, 7) + "   " at (0, 22).
    }
    else
    {
        print "ORBITAL SPEED    : " + round(ship:velocity:orbit:mag)    + "m/s   " at (0, 19).
        print "                                               " at (0, 20).
        print "                                               " at (0, 21).
        print "                                               " at (0, 22).
    }
}