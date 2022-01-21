@lazyGlobal off.

//-- Dependencies --//
runOncePath("0:/lib/globals.ks").

//-- Variables --//
local line to 10.

//-- Functions --//

//-- Display Utilities
// Clears a line assuming a 60 char display
global function clr
{
    parameter clrLine.
    print "                                                            " at (0, clrLine).
}

global function clrDisp
{
    parameter clrLine to 10.
    until clrLine = terminal:height - 1
    {
        clr(clrLine).
        set clrLine to clrLine + 1.
    }
}

// Local function for incrementing ln
global function cr
{
    set line to line + 1.
    return line.
}

// Formats a timestamp into one of a few format strings
global function DispTimeFormat
{
    parameter ts,
              format is "ts".

    set ts to TimeSpan(abs(ts)).
    
    local y  to ts:Year.
    local d  to ts:Day.
    local h  to ts:Hour.
    local m  to ts:Minute.
    local s  to ts:Second.
    local ms to ts:Seconds:ToString:Split(".")[1]:SubString(0, 3):ToNumber. // round(mod(ts:seconds, round(ts:seconds)), 3).

    if format = "ts"
    {
        local tsY  to choose y  if y  >= 10 else choose "0" + y  if y  >= 0 else "00".
        local tsD  to choose d  if d  >= 10 else choose "0" + d  if d  >= 0 else "00".
        local tsH  to choose h  if h  >= 10 else choose "0" + h  if h  >= 0 else "00".
        local tsM  to choose m  if m  >= 10 else choose "0" + m  if m  >= 0 else "00".
        local tsS  to choose s  if s  >= 10 else choose "0" + s  if s  >= 0 else "00".
        local tsMS to ms.
        
        return tsY + "y, " + tsD + "d T" + tsH + ":" + tsM + ":" + tsS + "." + tsMS.
    }
    else if format = "dateTime"
    {
        local dtY  to choose y  if y >= 1000 else choose "0" + y if y >= 100 else choose "00" + y if y >= 10 else "000" + y.
        local dtD  to choose d  if d  >= 100 else choose "0" + d  if d  >= 10 else "00" + d.
        local dtH  to choose h  if h  >= 10 else choose "0" + h  if h  >= 0 else "00".
        local dtM  to choose m  if m  >= 10 else choose "0" + m  if m  >= 0 else "00".
        local dtS  to choose s  if s  >= 10 else choose "0" + s  if s  >= 0 else "00".
        local dtMS to ms.
        
        return dtY + "-" + dtD + "T" + dtH + ":" + dtM + ":" + dtS + "." + dtMS.
    }
}

// Print a string to the hud with errorLevel
global function OutHUD 
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
global function OutInfo
{
    parameter str is "".
    //print "INFO : " + str + "          " at (0, 7).
    clr(7).
    print str at (0, 7).
}

global function OutInfo2
{
    parameter str is "".
    //print "INFO : " + str + "          " at (0, 8).
    clr(8).
    print str at (0, 8).
}

// Print a string to the msg line
global function OutMsg
{
    parameter str is "".
    //print "MSG  : " + str + "          " at (0, 6).
    clr(6).    
    print str at (0, 6).
}

// Prints to both hud and msg line
global function OutTee
{
    parameter str is "",
              pos is 0,
              errLvl is 0,
              screenTime is 15.

    if pos = 0 OutMsg(str).
    else if pos = 1 OutInfo(str).
    else if pos = 2 OutInfo2(str).
    OutHUD(str, errLvl, screenTime).
}

global function OutWait
{
    parameter str, 
              waitTime is 1.

    local charIdx to 0.
    local waitChar to list("", ".", "..", "...", "...").
    local ts to time:seconds + waitTime.
    until time:seconds >= ts
    {
        OutMsg(str + waitChar[charIdx]).
        set charIdx to choose 0 if charIdx = waitChar:length - 1 else charIdx + 1.
        wait 0.20.
    }
}

// Sets up the terminal
global function DispTerm
{
    set terminal:height to 50.
    set terminal:width to 60.
    core:doAction("open terminal", true).
}

//-- Main Displays
// A display for airplane flights
global function DispAvionics
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
global function DispLaunchPlan
{
    parameter launchPlan, planName.
    
    set line to 10.

    print "LAUNCH PLAN OVERVIEW" at (0, line).
    print "--------------------" at (0, cr()).
    cr().
    print "PLAN USED           : " + planName[0] at (0, cr()).
    if planName:length > 1 print "BRANCH USED         : " + planName[1] at (0, cr()).
    cr().
    print "PERIAPSIS           : " + launchPlan[0] at (0, cr()).
    print "APOAPSIS            : " + launchPlan[1] at (0, cr()).
    cr().
    print "INCLINATION         : " + launchPlan[2] at (0, cr()).
    print "LAUNCH LAN          : " + launchPlan[3] at (0, cr()).
    cr().
    //print "WAIT FOR LAN WINDOW : " + launchPlan:waitForLAN at (0, cr()).
}

global function DispLaunchWindow
{
    parameter tgtInc, tgtLAN, tgtEffectiveLAN, launchTime.

    set line to 10.

    print "LAUNCH WINDOW" at (0, line).
    print "-------------" at (0, cr()).
    cr().
    if hasTarget 
    print "TARGET           : " + target at (0, cr()).
    print "TARGET INC       : " + round(tgtInc, 1) at (0, cr()).
    print "TARGET LAN       : " + round(tgtLAN, 3) at (0, cr()).
    print "EFFECTIVE LAN    : " + round(tgtEffectiveLAN, 3) at (0, cr()).
    cr().
    print "CURRENT LAN      : " + round(ship:orbit:lan, 3) at (0, cr()).
    print "TIME TO LAUNCH   : " + dispTimeFormat(time:seconds - launchTime) at (0, cr()).
}


// A display header for mission control
global function DispMain
{
    parameter scrPlan is scriptPath():name,
              showTerminal is true.

    if showTerminal DispTerm().

    print "Mission Controller v2.0.1" at (0, 0).
    print "=========================" at (0, 1).
    print "MISSION : " + ship:name    at (0, 3).
    print "PLAN    : " + scrPlan         at (0, 4).
}

// Mnv details
global function DispBurn
{
    parameter dvToGo, burnETA, burnDur is 0.

    OutMsg("DV REMAINING    : " + round(dvToGo, 2)). 
    if burnETA >= 0 
    {
        set burnETA to abs(burnETA).
        if burnETA > 60
        {
            set burnETA to timeSpan(burnETA):full.
        }
        else
        {
            set burnETA to round(burnETA, 2).
        }
        OutInfo("BURN ETA        : " + burnETA).
        OutInfo2("BURN DURATION   : " + round(burnDur, 2) + "s     ").
    }
    else
    {
        OutInfo("BURN DURATION   : " + round(burnDur, 2) + "s     ").
        OutInfo2().
    }
}


// Results of a maneuver optimization
global function DispMnvScore
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
global function DispOrbit
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
global function DispImpact
{
    parameter tti is 0.

    set line to 10.

    print "LANDING TELEMETRY" at (0, line).
    print "-----------------" at (0, cr()).
    print "BODY           : " + ship:body:name   + "      " at (0, cr()).
    print "ALTITUDE       : " + round(ship:altitude)    + "m     " at (0, cr()).
    print "RADAR ALT      : " + round(ship:altitude - ship:geoposition:terrainheight)        + "m     " at (0, cr()).
    print "VERTICAL SPD   : " + round(ship:verticalspeed, 2) + "m/s   " at (0, cr()).
    print "TIME TO IMPACT : " + round(tti, 2)              + "s   " at (0, cr()).
}


// Simple landing telemetry
global function DispLanding
{
    parameter tti is 0, 
              burnDur is 0.

    set line to 10.

    print "LANDING TELEMETRY" at (0, line).
    print "-----------------" at (0, cr()).
    print "BODY           : " + ship:body:name   + "      " at (0, cr()).
    print "ALTITUDE       : " + round(ship:altitude)    + "m     " at (0, cr()).
    print "RADAR ALT      : " + round(ship:altitude - ship:geoposition:terrainheight)        + "m     " at (0, cr()).
    print "SURFACE SPD    : " + round(ship:groundspeed, 2) + "m/s   " at (0, cr()).
    print "VERTICAL SPD   : " + round(ship:verticalspeed, 2) + "m/s   " at (0, cr()).
    cr().
    print "THROTTLE       : " + round(throttle * 100)            + "%  " at (0, cr()).
    print "TIME TO IMPACT : " + round(tti, 2)              + "s   " at (0, cr()).
    print "BURN DURATION  : " + round(burnDur, 2)          + "s   " at (0, cr()).
}

// Generic API for printing a telemetry section, takes a list of header strings / values
global function DispGeneric
{
    parameter dispList, 
              stLine is 22.

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

// Provides a readout for /main/mission/gps
global function DispGPS
{
    parameter gpsModuleStatus, 
              orientation.

    set line to 10.

    print "GPS MISSION" at (0, line).
    print "-----------" at (0, cr()).
    print "GPS NODE         : " + Ship:Name:Split(" ")[1] at (0, cr()).
    print "GPS STATUS       : " + gpsModuleStatus:ToUpper at (0, cr()).
    print "TRACKING DIR     : " + orientation:ToUpper at (0, cr()).
    cr().
    print "ALTITUDE         : " + round(Ship:Altitude) + "m " at (0, cr()).
    //print "ORBITAL PERIOD   : " + TimeSpan(Ship:Orbit:Period):Full at (0, cr()).
    print "ORBITAL PERIOD   : " + DispTimeFormat(Ship:Orbit:Period, "dateTime") at (0, cr()).
}

// Provides a readout of pid values and output against tgt val
global function DispPIDReadout
{
    parameter pidName, pid, tgtVal is 0, curVal is 0.

    set line to 25.

    print "PIDTYPE: " + pidName at (0, line).
    print "TGTVAL : " + round(tgtVal, 5) + "     " at (0, cr()).
    print "CURVAL : " + round(curVal, 5) + "      " at (0, cr()).
    print "ERROR  : " + round(curVal - tgtVal, 5) + "     " at (0, cr()).
    cr().
    print "PIDOUT : " + round(pid:output, 2) + "     " at (0, cr()).
    cr().
    print "P TERM : " + round(pid:pterm, 5) + "     " at (0, cr()).
    print "I TERM : " + round(pid:iterm, 5) + "     " at (0, cr()).
    print "D TERM : " + round(pid:dterm, 5) + "     " at (0, cr()).
}

// General telemetry for flight
global function DispTelemetry
{
    parameter hasConnection to true.
    
    set line to 10.

    print "TELEMETRY" at (0, line).
    print "---------" at (0, cr()).

    if hasConnection
    {
        local altStr            to round(ship:altitude):ToString.
        local apStr             to round(ship:apoapsis):ToString.
        local peStr             to round(ship:periapsis):ToString.
        local throtStr          to round(Throttle * 100):ToString.
        local availThrStr       to round(ship:availablethrust, 2).
        local maxAccStr         to round(Ship:AvailableThrust / Ship:Mass, 2):ToString.
        local srfSpdStr         to round(ship:velocity:surface:mag):ToString.
        local kpaStr            to round(body:atm:altitudePressure(ship:altitude) * constant:AtmToKpa, 7):ToString.
        local qStr              to round(ship:q, 7):ToString.
        local orbSpdStr         to round(ship:velocity:orbit:mag):ToString.

        print "ALTITUDE         : " + altStr        + "m      " at (0, cr()).
        print "APOAPSIS         : " + apStr         + "m      " at (0, cr()).
        print "PERIAPSIS        : " + peStr         + "m      " at (0, cr()).
        cr().
        print "THROTTLE         : " + throtStr      + "%      " at (0, cr()).
        print "AVAIL THRUST     : " + availThrStr   + "kN     " at (0, cr()).
        print "MAX ACCELERATION : " + maxAccStr     + "m/s   " at (0, cr()).
        cr().
        if (Body:Atm:Exists) and ship:altitude < body:atm:height
        {
            print "SURFACE SPEED    : " + srfSpdStr + "m/s   " at (0, cr()).
            print "PRESSURE (KPA)   : " + kpaStr    + "   " at (0, cr()).
            print "Q                : " + qStr      + "     " at (0, cr()).
        }
        else
        {
            print "ORBITAL SPEED    : " + orbSpdStr + "m/s   " at (0, cr()).
            print "                                               " at (0, cr()).
            print "                                               " at (0, cr()).
            print "                                               " at (0, cr()).
        }
    }
    else
    {
        cr().
        cr().
        print "*** TELEMETRY LOST ***" at (13, cr()).
        cr().
        if (mod(time:seconds, 2) > 1) 
        {
            print "*** WAITING FOR SIGNAL REACQUISITION ***" at (4, cr()).
        }
        else
        {
            print "                                        " at (4, cr()).
        }
    }
}

// Resource transfer readout
global function DispResTransfer
{
    parameter resName, 
              src,
              srcCap,
              tgt,
              tgtCap,
              xfrAmt.

    set line to 10.

    local srcAmt to 0.
    local tgtAmt to 0.

    for r in src:resources
    {
        if r:name = resName set srcAmt to r:amount.
    }

    for r in tgt:resources
    {
        if r:name = resName set tgtAmt to r:amount.
    }

    print "RESOURCE TRANSFER" at (0, line).
    print "-----------------" at (0, cr()).
    print "RESOURCE             : " + resName at (0, cr()).
    print "TRANSFER AMOUNT      : " + round(xfrAmt, 2) at (0, cr()).
    print "TRANSFER PROGRESS    : " + round(1 - (xfrAmt / tgtAmt), 2) * 100 + "%   " at (0, cr()).
    cr().
    print "SOURCE ELEMENT       : " + src:name at (0, cr()).
    print "SOURCE AMOUNT / CAP  : " + round(srcAmt, 2) + " / " + round(srcCap) at (0, cr()).
    cr().
    print "TARGET ELEMENT       : " + tgt:name at (0, cr()).
    print "TARGET AMOUNT / CAP  : " + round(tgtAmt, 2) + " / " + round(tgtCap) at (0, cr()).
    cr().
}