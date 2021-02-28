@lazyGlobal off.

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
    padRight(str, 7).
}

// A display header for mission control
global function disp_main
{
    print "Mission Controller v0.02b" at (2, 2).
    print "=========================" at (2, 3).
    padRight("MISSION : " + ship:name, 4).
}

// Print a string to the msg line
global function disp_msg
{
    parameter str is " ".
    if str <> " " set str to "MSG : " + str.
    padRight(str, 6).
}

// Sets up the terminal
global function disp_terminal
{
    set terminal:height to 30.
    set terminal:width to 50.
    core:doAction("open terminal", true).
}

// Displays general telemetry for flight
global function disp_telemetry 
{
    parameter line is 10.
    print "TELEMETRY" at (2, line).
    print "---------" at (2, line + 1).
    set line to padRight("ALTITUDE     : " + round(ship:altitude) + "m", line + 2).
    set line to padRight("APOAPSIS     : " + round(ship:apoapsis) + "m", line).
    set line to padRight("PERIAPSIS    : " + round(ship:periapsis) + "m", line).
    set line to padRight("DYN PRESSURE : " + round(ship:q, 5), line).
    set line to cr(line).
    set line to padRight("THROTTLE     : " + round(throttle * 100) + "%", line).
    set line to padRight("THRUST       : " + round(ship:availablethrust, 2) + "kN", line).
    return line.
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
    print str:padRight(terminal:width - str:length) at (2, line).
    return line + 1.
}

global function padLeft
{
    parameter str, line.
    print str:padLeft(terminal:width - str:length) at (2, line).
    return line + 1.
}