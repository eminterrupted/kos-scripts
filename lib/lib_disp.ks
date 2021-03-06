@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//

//-- Functions --//

// Clears a line
global function disp_clr
{
    parameter line.
    print " ":padRight(terminal:width) at (0, line).
}

// Print a string to the info line
global function disp_info
{
    parameter str is " ".
    if str <> " " set str to "INFO: " + str.
    padRight(str, 6).
}

global function disp_info2
{
    parameter str is " ".
    if str <> " " set str to "INFO: " + str.
    padRight(str, 7).
}

// A display header for mission control
global function disp_main
{
    print "Mission Controller v0.02b" at (0, 1).
    print "=========================" at (0, 2).
    padRight("MISSION : " + ship:name, 3).
}

// Print a string to the msg line
global function disp_msg
{
    parameter str is " ".
    if str <> " " set str to "MSG : " + str.
    padRight(str, 5).
}

// Sets up the terminal
global function disp_terminal
{
    set terminal:height to 30.
    set terminal:width to 50.
    core:doAction("open terminal", true).
}

// Displays general telemetry for flight
global function disp_orbit
{
    parameter line is 10.
    print "ORBIT" at (0, line).
    print "---------" at (0, line + 1).
    set line to padRight("ALTITUDE     : " + round(ship:altitude) + "m", line + 2).
    set line to padRight("APOAPSIS     : " + round(ship:apoapsis) + "m", line).
    set line to padRight("PERIAPSIS    : " + round(ship:periapsis) + "m", line).
    set line to cr(line).
    return line.
}

global function disp_telemetry
{
    parameter line is 10.
    print "TELEMETRY" at (0, line).
    print "---------" at (0, line + 1).
    set line to padRight("ALTITUDE         : " + round(ship:altitude) + "m", line + 2).
    set line to padRight("APOAPSIS         : " + round(ship:apoapsis) + "m", line).
    set line to padRight("PERIAPSIS        : " + round(ship:periapsis) + "m", line).
    set line to cr(line).
    set line to padRight("THROTTLE         : " + round(throttle * 100) + "%", line).
    set line to padRight("AVAIL THRUST     : " + round(ship:availablethrust, 2) + "kN", line).
    set line to padRight("MAX ACCELERATION : " + round(ship:availableThrust / ship:mass, 2) + "m/s", line).
    set line to padRight("DYN PRESSURE     : " + round(ship:q, 5), line).
}

// Functions for string formatting
global function cr
{
    parameter line.
    return line + 1.
}

global function padRight
{
    parameter str, line.
    print str:padRight(terminal:width - str:length) at (0, line).
    return line + 1.
}

global function padLeft
{
    parameter str, line.
    print str:padLeft(terminal:width - str:length) at (0, line).
    return line + 1.
}