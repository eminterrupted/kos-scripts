@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//

//-- Functions --//

// Clears a line assuming a 60 char display
global function disp_clr
{
    parameter line.
    print "                                                            " at (0, line).
}

// Print a string to the info line
global function disp_info
{
    parameter str is "".
    if str <> "" 
    {
        set str to "INFO : " + str + "          ".
        print str at (0, 6).
    }
    else 
    {
        disp_clr(6).
    }
}

global function disp_info2
{
    parameter str is "".
    if str <> "" 
    {
        set str to "INFO : " + str + "          ".
        print str at (0, 7).
    }
    else 
    {
        disp_clr(7).
    }
}

// A display header for mission control
global function disp_main
{
    print "Mission Controller v0.02b" at (0, 1).
    print "=========================" at (0, 2).
    print "MISSION : " + ship:name at (0, 3).
}

// Print a string to the msg line
global function disp_msg
{
    parameter str is "".
    if str <> "" 
    {
        set str to "MSG  : " + str + "          ".
        print str at (0, 5).
    }
    else 
    {
        disp_clr(5).
    }
}

// Sets up the terminal
global function disp_terminal
{
    set terminal:height to 40.
    set terminal:width to 60.
    core:doAction("open terminal", true).
}

// Displays general telemetry for flight
global function disp_orbit
{
    print "ORBIT" at (0, 10).
    print "---------" at (0, 11).
    print "ALTITUDE     : " + round(ship:altitude)  + "m      " at (0, 12).
    print "APOAPSIS     : " + round(ship:apoapsis)  + "m      " at (0, 13).
    print "PERIAPSIS    : " + round(ship:periapsis) + "m      " at (0, 14).
}

global function disp_telemetry
{
    print "TELEMETRY" at (0, 10).
    print "---------" at (0, 11).
    print "ALTITUDE         : " + round(ship:altitude)              + "m      " at (0, 12).
    print "APOAPSIS         : " + round(ship:apoapsis)              + "m      " at (0, 13).
    print "PERIAPSIS        : " + round(ship:periapsis)             + "m      " at (0, 14).

    print "THROTTLE         : " + round(throttle * 100)             + "%      " at (0, 16).
    print "AVAIL THRUST     : " + round(ship:availablethrust, 2)    + "kN     " at (0, 17).

    print "MAX ACCELERATION : " + round(ship:availableThrust / ship:mass, 2) + "m/s   " at (0, 19).
    if ship:altitude >= 60000 
    {
        print "SURFACE SPEED    : " + round(ship:velocity:surface:mag)  + "m/s   " at (0, 20).
    }
    else
    {
        print "ORBITAL SPEED    : " + round(ship:velocity:orbit:mag)    + "m/s   " at (0, 20).
    }
}