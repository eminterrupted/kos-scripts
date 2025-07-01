@LazyGlobal off.
ClearScreen.

Terminal:Input:Clear.

until Terminal:Input:HasChar
{
    if Mod(Time:Seconds, 3) < 2
    {
        print "{0,48}  ":Format("*** Press any key to start countdown ***") at (5, 25).
    }
    else
    {
        print "{0,48}  ":Format(" ") at (5, 25).
    }
}

clearScreen.
wait until Stage:Ready.

local tVal is 1.
lock throttle to tVal.

// local sVal to Ship:Facing.
// lock steering to sVal.

SAS on.

local countdown to Time:Seconds + 3.
local frmStr to "{0,-14}: {1,-7}{2,-3}  ".

local _line to 10.
local baseLine to _line - 1.

local termObjects to lexicon(
    "Countdown", { return frmStr:Format("Countdown", Round(countdown - Time:Seconds, 1), "s").}
).

until Time:Seconds >= countdown 
{
    set _line to baseLine.
    for key in termObjects:Keys
    {
        print termObjects[key]:Call() at (2, cr()).
    }
    // print "Countdown: T-{0,4}s ":format(Round(countdown - Time:Seconds, 1)) at (2, 12).
}

stage.

local setupLex to lex(
    "Clock",         { return frmStr:Format("Clock", Round(Time:Seconds - countdown, 1), "s").}
    ,"_0", { return " ".}
    ,"_1", { return " ".}
    ,"Eng Thrust",   { return frmStr:Format("Eng Thrust", Round(Ship:Thrust, 1), "kn").}
    ,"Avail Thrust", { return frmStr:Format("Avail Thrust", Round(Ship:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)), 1), "kn"). }
    ,"Thrust Perf ", { return frmStr:Format("Thrust Perf", Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100, "kn"). }
    ,"_2", { return " ".}
).

for key in setupLex:Keys
{
    termObjects:Add(key, setupLex[key]).
}
termObjects:Remove("Countdown").

until Ship:Thrust >= Ship:AvailableThrust * 0.92 and Stage:Ready
{
    set _line to baseLine.
    for key in termObjects:Keys
    {
        print termObjects[key]:Call() at (2, cr()).
    }

    // print "Clock        : T+{0,4}s ":format(Round(Time:Seconds - countdown, 1)) at (2, 12).
    // print "Ship Thrust  : {0,-5}kn ":format(Round(Ship:Thrust, 1)) at (2, 15).
    // print "Avail Thrust : {0,-5}kn ":format(Round(Ship:AvailableThrust, 1)) at (2, 16).
    // print "Thrust Perf  : {0,-6}% ":format(Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100) at (2, 17).
}
stage.
clearScreen.

set setupLex to lex(
    "Altitude", { return frmStr:Format("Altitude", Round(Ship:Altitude), "m"). }
    ,"_3", { return " ".}
    ,"_4", { return " ".}
    ,"Surface Velo",  { return frmStr:Format("Surface Velo", Round(Ship:Velocity:Surface:Mag), "m/s").}
    ,"Orbital Velo",  { return frmStr:Format("Orbital Velo", Round(Ship:Velocity:Orbit:Mag), "m/s").}
    ,"VerticalSpeed", { return frmStr:Format("VerticalSpeed", Round(Ship:VerticalSpeed, 1), "m/s").}
).

for key in setupLex:Keys
{
    termObjects:Add(key, setupLex[key]).
}

ClearScreen.


until Stage:Number = 0 or Ship:Engines:Length = 0
{
    if Ship:Thrust <= 0.1
    {
        if Stage:Ready
        {
            stage.
        }

        set _line to baseLine.
        for key in termObjects:Keys
        {
            print termObjects[key]:Call() at (2, cr()).
        }


        // print "Clock        : T+{0,-4}s ":format(Round(Time:Seconds - countdown, 1)) at (2, 12).
        // print "Ship Thrust  : {0,-6}kn ":format(Round(Ship:Thrust, 1)) at (2, 15).
        // print "Avail Thrust : {0,-6}kn ":format(Round(Ship:AvailableThrust, 1)) at (2, 16).
        // print "Thrust Perf  : {0,-6}% ":format(Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100) at (2, 17).
        
        // print "Altitude     : {0,-6}m ":format(Round(Ship:Altitude)) at (2, 20).

        // print "Surface Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Surface:Mag)) at (2, 24).
        // print "Orbital Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Orbit:Mag)) at (2, 25).
        // print "VerticalSpeed: {0,-6}m/s ":format(Round(Ship:VerticalSpeed)) at (2, 26).
    }
    else
    {
        set _line to baseLine.
        for key in termObjects:Keys
        {
            print termObjects[key]:Call() at (2, cr()).
        }

        // print "Clock        : T+{0,-4}s ":format(Round(Time:Seconds - countdown, 1)) at (2, 12).
        // print "Ship Thrust  : {0,-6}kn ":format(Round(Ship:Thrust, 1)) at (2, 15).
        // print "Avail Thrust : {0,-6}kn ":format(Round(Ship:AvailableThrust, 1)) at (2, 16).
        // print "Thrust Perf  : {0,-6}% ":format(Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100) at (2, 17).
        
        // print "Altitude     : {0,-6}m ":format(Round(Ship:Altitude)) at (2, 20).

        // print "Surface Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Surface:Mag)) at (2, 24).
        // print "Orbital Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Orbit:Mag)) at (2, 25).
        // print "VerticalSpeed: {0,-6}m/s ":format(Round(Ship:VerticalSpeed)) at (2, 26).
    }
}

ClearScreen.

until Ship:VerticalSpeed <= 0.001
{
    set _line to baseLine.
    for key in termObjects:Keys
    {
        print termObjects[key]:Call() at (2, cr()).
    }
    // print "Clock        : T+{0,-4}s ":format(Round(Time:Seconds - countdown, 1)) at (2, 12).
    // print "Ship Thrust  : {0,-6}kn ":format(Round(Ship:Thrust, 1)) at (2, 15).
    // print "Avail Thrust : {0,-6}kn ":format(Round(Ship:AvailableThrust, 1)) at (2, 16).
    // print "Thrust Perf  : {0,-6}% ":format(Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100) at (2, 17).
    
    // print "Altitude     : {0,-6}m ":format(Round(Ship:Altitude)) at (2, 20).

    // print "Surface Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Surface:Mag)) at (2, 24).
    // print "Orbital Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Orbit:Mag)) at (2, 25).
    // print "VerticalSpeed: {0,-6}m/s ":format(Round(Ship:VerticalSpeed)) at (2, 26).
}

local maxAlt to Round(Ship:Altitude, 1).



until False
{
    set _line to baseLine.
    for key in termObjects:Keys
    {
        print termObjects[key]:Call() at (2, cr()).
    }

    // print "Clock        : T+{0,-4}s ":format(Round(Time:Seconds - countdown, 1)) at (2, 12).
    // print "Ship Thrust  : {0,-6}kn ":format(Round(Ship:Thrust, 1)) at (2, 15).
    // print "Avail Thrust : {0,-6}kn ":format(Round(Ship:AvailableThrust, 1)) at (2, 16).
    // print "Thrust Perf  : {0,-6}% ":format(Round(Max(0.0000001, Ship:Thrust) / Max(0.0000001, Ship:availablethrust)) * 100) at (2, 17).
    
    // print "Altitude     : {0,-6}m ":format(Round(Ship:Altitude)) at (2, 20).
    // print "Altitude Max : {0,-6}m ":format(maxAlt) at (2, 21).

    // print "Surface Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Surface:Mag)) at (2, 24).
    // print "Orbital Velo : {0,-6}m/s ":format(Round(Ship:Velocity:Orbit:Mag)) at (2, 25).
    // print "VerticalSpeed: {0,-6}m/s ":format(Round(Ship:VerticalSpeed)) at (2, 26).
}

local function cr
{
    parameter __line is _line,
              __incr is 1.

    set _line to __line + __incr.
    return _line.
}