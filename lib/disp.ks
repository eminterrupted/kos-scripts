@lazyGlobal off.

//-- Dependencies --//
runOncePath("0:/lib/globals.ks").

//-- Variables --//
// global g_line to 10. // moved to lib/globals/ks
local d_tHeight to 50.
local d_tWidth to 60.
// local tel_Height to 101.
// local tel_Width to 86.

//-- Functions --//

//-- Display Utilities
// Clears a line assuming a 60 char display
global function clr
{
    parameter clrLine.
    
    local str to "{0, " + -terminal:width + "}".
    print str:format("") at (0, clrLine).
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

// Clears display and resets g_line
global function ResetDisp
{
    parameter resetSize is false.

    clrDisp().
    set g_line to 10.
    if resetSize 
    {
        InitTerm().
    }
}

// Helper function that increments g_line then clears that line for cleaner printing.
global function clrCR
{
    parameter fromLine to g_line.

    set g_line to fromLine + 1.
    clr(g_line).
    return g_line.
}

// Local function for incrementing g_line
global function cr
{
    parameter fromLine to g_line.

    set g_line to fromLine + 1.
    return g_line.
}

global function DispMnvPatchList
{
    parameter _mnv,
              line is 10.

    set g_line to line.

    print "{0, 10}   {1, 10}   {2}":format("PATCH IDX", "PATCH SOI", "ETA") at (0, line).
    local patchList to GetPatchesForNode(_mnv).
    from { local i to 0. } until i = patchList:length step { set i to i + 1. } do
    {
        local len to i:toString():length.
        local padUp to round((10 - len) / 2) - 1.
        local padFlr to floor((10 - len) / 2) - 1.
        local str to "[{0, " + padUp + "}{1}{0, " + padFlr + "}]  {1, 10}   {2}".
        print str:format("", i, patchList[i]:body:name) at (0, cr()).
    }
}

global function DispPatchList
{
    parameter tgtVes is ship,
              line is 10.

    set g_line to line.

    print "{0, 10}   {1, 10}   {2}":format("PATCH IDX", "PATCH SOI", "ETA") at (0, line).
    from { local i to 0. local o to ship:orbit. } until i = tgtVes:patches:length step { set i to i + 1. if o:hasNextPatch set o to o:nextPatch. } do
    {
        local len to i:toString():length.
        local padUp to round((10 - len) / 2) - 1.
        local padFlr to floor((10 - len) / 2) - 1.
        local str to "[{0, " + padUp + "}{1}{0, " + padFlr + "}]  {1, 10}   {2}".
        print str:format("", i, o:body:name) at (0, cr()).
    }
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
    parameter 
        str is "", 
        errLvl is 0,
        pos is 0.

    local msgType to "".
    if errLvl = 1 set msgType to "WARN: ".
    else if errLvl = 2 set msgType to "ERR: ".
    clr(6 + pos).
    print msgType + str at (0, 6 + pos).
}

// Prints to both hud and msg line
global function OutTee
{
    parameter str is "",
              pos is 0,
              errLvl is 0,
              screenTime is 15.

    if pos:isType("Scalar")
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

// RoundDistance - Rounds a distance to the given precision.
// TODO - Implement precision options. Currently only Float is available, which 
// will simply adjust the denominator to 'nnn,nnn<unit>', whatever that unit ends
// up being
local function RoundDistance
{
    parameter dist,
              precision is "float".

    if precision = "float"
    {
        if dist <= 999999 return round(dist):ToString + "m".
        else if dist <= 999999999 return round(dist / 1000):ToString + "Km".
        else if dist <= 999999999999 return round(dist / 1000000):ToString + "Mm".
        else if dist <= 999999999999999 return round(dist / 1000000000):ToString + "Gm".
        else return round(dist / 1000000000000):ToString + "Tm".
    }
}

// PrettyDur :: [<scalar>Seconds] -> <string>
local function PrettyDur
{
    parameter _dur to 0.

    if _dur = 0
    {
        return " N/A".
    }
    else
    {
        set _dur to timespan(_dur).
        local dayStr to "".
        local yearStr to "".

        if _dur:day > 0 set dayStr to "{0,2}d ":format(_dur:day).
        if _dur:year > 0 set yearStr to "{0,2}y ":format(_dur:year).
        local timeStr to "{0:0,2}h {1:0,2}m {2:0,2}s":format(_dur:hour, _dur:minute, _dur:second).
        return yearStr + dayStr + timeStr.
    }
}


// Sets up the terminal
global function InitTerm
{
    ClearScreen.
    set Terminal:Height to d_tHeight.
    set Terminal:Width to d_tWidth.
    Core:DoAction("open terminal", true).
}

//-- Main Displays
// A display for airplane flights
global function DispAvionics
{
    set g_line to 10.
    
    print "AVIONICS" at (0, g_line).
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

// Display for a Flyby of a body
global function DispFlyBy
{
    parameter radarAlt to Ship:Altitude - Ship:GeoPosition:TerrainHeight.
    
    set g_line to 10.

    local sciSitu to choose "High" if ship:altitude >= BodyInfo:altForSci[Body:Name] else "Low".

    print "FLYBY DATA" at (0, g_line).
    print "----------" at (0, cr()).
    print "ALTITUDE     : " + round(ship:altitude) at (0, cr()).
    print "RDR ALTITUDE : " + round(radarAlt) at (0, cr()).
    print "SRF SPEED    : " + round(ship:velocity:surface:mag, 1) at (0, cr()).
    print "SITUATION    : " + Body:Name + ": " + sciSitu + " over " + addons:scansat:getBiome(ship:body, ship:geoposition) at (0, cr()).
    cr().
    print "APPROACH" at (0, cr()).
    print "EST APPROACH ALT : " + round(ship:periapsis) at (0, cr()).
    print "EST APPROACH ETA : " + TimeSpan(eta:periapsis):full at (0, cr()).
}

// Display for inclination burn details
global function DispIncChange
{
    parameter shipOrbit,
              tgtOrbit.

    set g_line to 10.

    print "INCLINATION CHANGE PARAMETERS" at (0, g_line).
    print "-----------------------------" at (0, cr()).
    cr().
    print "              CURRENT  |   TARGET" at (0, cr()).
    print "INCLINATION :  " + round(shipOrbit:Inclination, 1) at (0, cr()).
        print round(tgtOrbit:Inclination, 1) at (28, g_line).
    print "LAN         :  " + round(shipOrbit:LAN, 1) at (0, cr()). 
        print round(tgtOrbit:LAN, 1) at (28, g_line).
}

// Display mission plan
global function DispMissionPlan
{
    parameter mPlan is list(),
              titleStr is ship:name + " Mission plan".

    ResetDisp().
    
    if mPlan:length = 0
    {
        if exists("mp.json")
        {
            set mPlan to readJson("mp.json").
        }
        else
        {
            OutMsg("ERROR: Cannot display mission plan").
            OutInfo("       No mission plan provided or exists on disk").
            return 1.
        }
    }

    local titleBar to "".
    for rIdx in range(0, titleStr:length - 1, 1)
    {
        set titleBar to titleBar + "-".
    }
    print titleStr:toUpper at (0, g_line).
    print titleBar at (0, cr()).
    from { local i to 0. local line to g_line.} until i >= mPlan:length - 1 step { set i to i + 2. set line to line + 1.} do
    {
        local scr to mPlan[i].
        local prm to mPlan[i + 1].
        
        if line >= Terminal:Height - 5
        {
            ResetDisp().
            print titleStr:toUpper at (0, g_line).
            print titleBar at (0, cr()).
            set line to g_line.
        }
        
        print ("{0, -3} | {1, -25} | ({2, -50})"):format(i, scr, prm:join(";")) at (0, cr()).
    }
}

// Display for orbit changes
global function DispOrbitChange
{
    parameter tgtPe,
              tgtAp,
              tgtApe.

    set g_line to 10.

    print "ORBIT CHANGE PARAMETERS" at (0, g_line).
    print "-----------------------" at (0, cr()).
    cr().
    print "              CURRENT  |   TARGET" at (0, cr()).
    print "APOAPSIS  :    " + round(ship:orbit:apoapsis) at (0, cr()).
        print round(tgtAp) at (28, g_line).
    print "PERIAPSIS :    " + round(ship:orbit:periapsis) at (0, cr()). 
        print round(tgtPe) at (28, g_line).
    print "ARG PE    :    " + round(ship:orbit:argumentofperiapsis, 1) at (0, cr()).
        print round(tgtApe, 1) at (28, g_line).
}

// Displays the launch plan prior to launching
global function DispLaunchPlan
{
    parameter launchPlan, planName, noAtmoStageAtLaunch is 0.
    
    set g_line to 10.

    print "LAUNCH PLAN OVERVIEW" at (0, g_line).
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
    if noAtmoStageAtLaunch <> 0 print "STAGE AT LAUNCH     : " + noAtmoStageAtLaunch at (0, cr()).
    //print "WAIT FOR LAN WINDOW : " + launchPlan:waitForLAN at (0, cr()).
}

// A special version of DispTelemetry with desired target info
global function DispLaunchTelemetry
{
    parameter _lp.
    
    local tgtPe to round(ship:apoapsis).
    local tgtAp to round(ship:apoapsis).
    local tgtInc to 0.
    local tgtLAN to -1.
    
    if _lp:length > 0 
    {
        set tgtPe to round(_lp[0]).
        if _lp:length > 1 
        {
            set tgtAp to round(_lp[1]).
            if _lp:length > 2 
            {
                set tgtInc to round(_lp[2], 2).
                if _lp:length > 3 
                {
                    set tgtLAN to round(_lp[3], 2).
                }
            }
        }
    }
    
    set g_line to 10.

    print "LAUNCH TELEMETRY" at (0, g_line).
    print "----------------" at (0, cr()).
    cr().
    local altStr            to round(ship:altitude):ToString.
    local apStr             to round(ship:apoapsis):ToString.
    local peStr             to round(ship:periapsis):ToString.
    local incStr            to round(ship:orbit:inclination, 3):ToString.
    local lanStr            to round(ship:orbit:LAN, 3):ToString.
    local throtStr          to round(Throttle * 100):ToString.
    local availThrStr       to round(ship:availablethrust, 2).
    local maxAccStr         to round(Ship:AvailableThrust / Ship:Mass, 2):ToString.
    local srfSpdStr         to round(ship:velocity:surface:mag):ToString.
    local kpaStr            to round(body:atm:altitudePressure(ship:altitude) * constant:AtmToKpa, 7):ToString.
    local qStr              to round(ship:q, 7):ToString.
    local orbSpdStr         to round(ship:velocity:orbit:mag):ToString.

    local apPctTgt          to round((ship:apoapsis / tgtAp) * 100, 2).
    local pePctTgt          to round((ship:periapsis / tgtPe) * 100, 2).
    local incPctTgt         to 100 - round(((ship:orbit:inclination - tgtInc) / 90) * 100, 2).
    local LANPctTgt         to choose 100 if tgtLAN < 0 else round((max(0.0000001, ship:orbit:LAN) / max(0.0000001, tgtLAN)) * 100, 2).

    print "ORBITAL INFO:" at (0, cr()).
    print "{0,18}: {1,-10}":format("ALTITUDE", altStr + "m ") at (0, cr()).
    print "{0,18}: {1,-10}":format("RADAR ALTITUDE", round(alt:radar)      + "m ") at (0, cr()).
    cr().
    print "{0,18}: {1,-10} | {2, -10} | {3}%  ":format("APOAPSIS", apStr + "m ", tgtAp + "m ", apPctTgt) at (0, cr()).
    print "{0,18}: {1,-10} | {2, -10} | {3}%  ":format("PERIAPSIS", peStr + "m ", tgtPe + "m ", pePctTgt) at (0, cr()).
    cr().  
    print "{0,18}: {1,-10} | {2, -10} | {3}%  ":format("INCLINATION", incStr + char(176) + " ", tgtInc + char(176) + " ", incPctTgt) at (0, cr()).
    print "{0,18}: {1,-10} | {2, -10} | {3}%  ":format("LONG OF ASC NODE", lanStr + char(176) + " ", tgtLAN + char(176) + " ", LANPctTgt) at (0, cr()).
    cr().  
    print "{0,18}: {1,-25}":format("THROTTLE", throtStr + "% ") at (0, cr()).
    print "{0,18}: {1,-25}":format("AVAIL THRUST", availThrStr + "kN ") at (0, cr()).
    print "{0,18}: {1,-25}":format("MAX ACCELERATION", maxAccStr + "m/s ") at (0, cr()).
    cr().
    if (Body:Atm:Exists) and ship:altitude < body:atm:height
    {
        print "{0,18}: {1,-25}":format("SURFACE SPEED", srfSpdStr + "m/s ") at (0, cr()).
        print "{0,18}: {1,-25}":format("PRESSURE (KPA)", kpaStr + " ") at (0, cr()).
        print "{0,18}: {1,-25}":format("PRESSURE (Q)", qStr + " ") at (0, cr()).
    }  
    else  
    {  
        print "{0,18}: {1,-25}":format("ORBITAL SPEED", orbSpdStr + "m/s ") at (0, cr()).
        print "                                               " at (0, cr()).
        print "                                               " at (0, cr()).
        print "                                               " at (0, cr()).
    }
}

global function DispLaunchWindow
{
    parameter tgtInc, tgtLAN, tgtEffectiveLAN, launchTime.

    set g_line to 10.

    print "LAUNCH WINDOW" at (0, g_line).
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

global function DispLaunchWindow2
{
    parameter launchTime, tgtInc, tgtLAN, srfSpd, lanAdjust, tgtEffectiveLAN.

    set g_line to 10.

    print "LAUNCH WINDOW 2" at (0, g_line).
    print "---------------" at (0, cr()).
    cr().
    if hasTarget 
    print "TARGET           : " + target at (0, cr()).
    print "OBT VEL AT LAT   : " + round(srfSpd, 2) + "m/s " at (0, cr()).
    cr().
    print "TARGET INC       : " + round(tgtInc, 1) at (0, cr()).
    print "TARGET LAN       : " + round(tgtLAN, 3) at (0, cr()).
    print " + LAN ADJUST    : " + round(lanAdjust, 3)  at (0, cr()).
    print "TGT EFFECTIVE LAN: " + round(tgtEffectiveLAN, 3) at (0, cr()).
    cr().
    print "CURRENT LAN      : " + round(ship:orbit:lan, 3) at (0, cr()).
    print "TIME TO LAUNCH   : " + dispTimeFormat(launchTime ) at (0, cr()).
}

// DispBoot :: <none> | <none>
global function DispBoot
{
    InitTerm().

    print "CREI-KASA Boot Loader v2.0b".
    print "===========================".
    print "MISSION          : " + ship:name.
    print "CURRENT STATUS   : " + ship:status.
    print "COMM STATUS      : " + homeConnection:isConnected.
    if Addons:Available:RT
    {
        print "COMM STATUS      : " + homeConnection:isConnected.
    }
    else
    {
        print "COMM STATUS      : N/A".
    }
    wait 0.25.
}

// A display header for mission control
global function DispMain
{
    parameter scrPlan is scriptPath():name,
              init is true.
    
    if init InitTerm().

    print "Mission Controller v2.0.1".// at (0, 0).
    print "=========================".// at (0, 1).
    print "MISSION : " + ship:name.//    at (0, 3).
    print "PLAN    : " + scrPlan.//         at (0, 4).
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

    set g_line to 10.
    
    print "NODE OPTIMIZATION"               at (0, g_line).
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
    parameter orientation is "".

    set g_line to 10.
    
    print "ORBIT" at (0, g_line).
    print "---------" at (0, cr()).
    print "BODY         : " + ship:body:name        + "       " at (0, cr()).
    print "ALTITUDE     : " + round(ship:altitude)  + "m      " at (0, cr()).
    print "APOAPSIS     : " + round(ship:apoapsis)  + "m      " at (0, cr()).
    print "PERIAPSIS    : " + round(ship:periapsis) + "m      " at (0, cr()).
    if orientation = "" 
    {
        return.
    } 
    else
    {
        cr().
        print "ORIENTATION  : " + orientation + "     " at (0, cr()).
    }
}

// Impact telemetry
global function DispImpact
{
    parameter tti is -1,
              radarAlt is Ship:Altitude - Ship:GeoPosition:TerrainHeight.

    set g_line to 10.

    print "IMPACT TELEMETRY" at (0, g_line).
    print "-----------------" at (0, cr()).
    print "BODY           : " + ship:body:name   + "      " at (0, cr()).
    print "ALTITUDE       : " + round(ship:altitude)    + "m     " at (0, cr()).
    print "RADAR ALT      : " + round(radarAlt)        + "m     " at (0, cr()).
    print "VERTICAL SPD   : " + round(ship:verticalspeed, 2) + "m/s   " at (0, cr()).
    if tti > 0.25
    {
        print "TIME TO IMPACT : {0} ":format(PrettyDur(tti)) at (0, cr()).
    }
    else if tti > -1
    {
        print "IMPACT!                             " at (0, cr()).
    }
    else
    {
        print "                                    " at (0, cr()).
    }
}


// Simple landing telemetry
global function DispLanding
{
    parameter program is 0,
              tgtAlt is 0,
              tgtSrfSpd is 0,
              tgtVertSpd is 0,
              radarAlt is Ship:Altitude - Ship:GeoPosition:TerrainHeight,
              tti is -1, 
              burnDur is -1.

    set g_line to 10.

    print "LANDING TELEMETRY" at (0, g_line).
    print "-----------------" at (0, cr()).
    print "PROGRAM        : " + program + "  " at (0, cr()).
    print "TARGET ALT     : " + tgtAlt + "m   " at (0, cr()).
    print "TARGET SRF SPD : " + tgtSrfSpd + "m/s   " at (0, cr()).
    print "TARGET VERT SPD: " + tgtVertSpd + "m/s  " at (0, cr()).
    cr().
    print "ALTITUDE       : " + round(Ship:Altitude)                + "m     " at (0, cr()).
    print "RADAR ALT      : " + round(radarAlt)       + "m     " at (0, cr()).
    print "SURFACE SPD    : " + round(Ship:Velocity:Surface:Mag, 2)          + "m/s   " at (0, cr()).
    print "GROUND SPD     : " + round(Ship:Groundspeed, 2) + "m/s  " at (0, cr()).
    print "VERTICAL SPD   : " + round(Ship:VerticalSpeed, 2)        + "m/s   " at (0, cr()).
    cr().
    print "THROTTLE       : " + round(throttle * 100)               + "%  " at (0, cr()).
    print "TWR            : " + round(GetTWRForStage(), 2) + "     " at (0, cr()).
    if tti > -1      print "TIME TO IMPACT : " + round(tti, 2)                       + "s   " at (0, cr()).
    if burnDur > -1  print "BURN DURATION  : " + round(burnDur, 2)                   + "s   " at (0, cr()).
}


// DispSOIData :: [<Body>Target] -> <int>Status Code
global function DispSOIData
{
    parameter tgtBody is ship:body.

    set g_line to 10.
    
    print "SOI INFO" at (0, cr()).
    print "--------" at (0, cr()).
    print "CURRENT      : " + ship:body:name at (0, cr()).
    local soiRad to choose round(ship:body:soiradius / 1000) + "km " if ship:body <> Sun else "UKN          ".
    print "SOI RADIUS   : " + soiRad at (0, cr()).
    cr().
    if tgtBody <> ship:body
    {
        local _t to GetSoiEta(tgtBody).
        set _t to choose PrettyDur(_t) if _t > -1 else "N/A".
        print "TARGET      : " + tgtBody:name at (0, cr()).
        print "ETA         : " + _t + " " at (0, cr()).
        cr().
    }
    cr().
    print "PATCH DETAILS" at (0, cr()).
    print "-------------" at (0, cr()).
    cr().
    local patchesLex to GetOrderedPatches(ship).
    print "  IDX   BODY       SOI ETA          DISTANCE" at (0, cr()).
    print "  ---   ----       -------          --------" at (0, cr()).
    for pKey in patchesLex:keys
    {
        print "   {0}  {1, 8}    {2, -16}   {3, -10}":format(pKey, patchesLex[pKey][0], PrettyDur(patchesLex[pKey][1]), RoundDistance(patchesLex[pKey][2])) at (0, cr()).
    }
    // if ship:patches:length > 0
    // {
        //print "PLAN PATCHES : " + ship:patches:length + " " at (0, cr()).
        // print "NEXT PATCH SOI    : " + ship:patches[1]:body:name + " " at (0, cr()).
        // print "ETA TO SOI        : " + PrettyDur(ship:orbit:nextpatcheta) + " " at (0, clrCR()).
        // cr().
        // local interceptPatch to GetInterceptPatchIndex(tgtBody).
        // local patchLex to GetOrderedPatches(ship).
        // if interceptPatch > 0
        // {
        //     print "INTERCEPT PATCH   : " + interceptPatch + " " at (0, clrCR()).
        //     print "INTERCEPT ETA     : " + GetPatchByIndex(interceptPatch - 1).
        // }
        // else
        // {
        //     print "*** NO INTERCEPT DETECTED ***" at (0, clrCR()).
        // }
    // }
    return 0.
}


// Generic API for printing a telemetry section, takes a list of header strings / values
global function DispGeneric
{
    parameter dispElements, 
              stLine is 22.

    set g_line to stLine.
    
    from { local idx is 0.} until idx >= dispElements:length step { set idx to idx + 1.} do 
    {
        if idx = 0 
        {
            print dispElements[idx] at (0, g_line).
            print "--------------" at (0, cr()).
            cr().
        }
        else
        {
            print dispElements[idx]:toUpper at (0, g_line).
            print ":     " at (16, g_line).
            set idx to idx + 1.
            print dispElements[idx] at (18, g_line).
            cr().
        }
    }
}

global function DispFileList
{
    parameter itemList,
              stLine to 10.

    set g_line to stLine.

    local iCurrent to itemList:iterator.
    local iType to "".
    print "Choose Item by index" at (2, g_line).
    cr().
    print ("{0, -3}  {1, -10}  {2}"):format("Idx", "Item Type", "Item") at (2, cr()).
    print ("{0, -3}  {1, -10}  {2}"):format("---", "---------", "----") at (2, cr()).
    until not iCurrent:next
    {
        set iType to choose "File" if iCurrent:value:isFile else "Directory".
        print ("{0, 3}  {1, -10}  {2}"):format(iCurrent:index, iType, iCurrent:value) at (2, cr()).
    }
}

// Provides a readout for /main/mission/gps
global function DispGPS
{
    parameter gpsModuleStatus, 
              orientation.

    set g_line to 10.

    print "GPS MISSION" at (0, g_line).
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

    set g_line to 25.

    print "PIDTYPE: " + pidName at (0, g_line).
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
    parameter hasConnection to true, 
              radarAlt to Round(Ship:Altitude - Ship:GeoPosition:TerrainHeight).
    
    set g_line to 10.

    print "TELEMETRY" at (0, g_line).
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
        print "RADAR ALTITUDE   : " + radarAlt      + "m      " at (0, cr()).
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

// global function DispLaunchTelemetry
// {
//     parameter tgtAp, 
//               tgtPe,
//               tgtVel.
    
//     set g_line to 10.

//     print "TELEMETRY" at (0, g_line).
//     print "---------" at (0, cr()).

//     print "{0,-18}: {1, -15}":format("ALTITUDE", round(ship:altitude)) at (0, cr()).
//     print "{0,-18}: {1, -15}":format("RADAR ALTITUDE", round(Ship:Altitude - Ship:GeoPosition:TerrainHeight)) at (0, cr()).
//     print "{0,-18}: {1, -15} {2, -15}":format("APOAPSIS", round(ship:apoapsis), tgtAp) at (0, cr()).
//     print "{0,-18}: {1, -15} {2, -15}":format("PERIAPSIS", round(ship:periapsis), tgtPe) at (0, cr()).
//     cr().
//     print "{0,-18}: {1, -15}":format("THROTTLE", round(throttle * 100)) at (0, cr()).
//     // print "{0,-18}: {1, -15}":format("CUR THRUST", round(0)) at (0, cr()).
//     print "{0,-18}: {1, -15}":format("AVAIL THRUST", round(Ship:AvailableThrust, 2)) at (0, cr()).
//     print "{0,-18}: {1, -15}":format("TWR", round(Ship:AvailableThrust * tConstants:KnToKg)) at (0, cr()).
//     print "{0,-18}: {1, -15}":format("MAX ACCELERATION", round(Ship:AvailableThrust / Ship:Mass, 2)) at (0, cr()).
//     cr().
//     if (Body:Atm:Exists) and ship:altitude < body:atm:height
//     {
//         print "{0,-18}: {1, -15}":format("SURFACE SPEED", round(ship:velocity:surface:mag)) at (0, cr()). 
//         print "{0,-18}: {1, -15}":format("PRESSURE (KPA)", round(body:atm:altitudePressure(ship:altitude) * constant:AtmToKpa, 7)) at (0, cr()).
//         print "{0,-18}: {1, -15}":format("PRESSURE (ATM)", round(body:atm:altitudePressure(ship:altitude), 7)) at (0, cr()).
//         print "{0,-18}: {1, -15}":format("PRESSURE (Q)",   round(ship:q, 7)) at (0, cr()).
//     }
//     else
//     {
//         print "{0,-18}: {1, -15} {2, -15}":format("ORBITAL SPEED", round(ship:velocity:orbit:mag), tgtVel) at (0, cr()).
//         print "                                               " at (0, cr()).
//         print "                                               " at (0, cr()).
//         print "                                               " at (0, cr()).
//     }
// }

// Resource transfer readout
global function DispResTransfer
{
    parameter src,
              tgt,
              srcRes,
              xfrAmt.

    set g_line to 10.

    local srcAmt to srcRes:amount.
    local finalAmt to 0.
    local tgtRes to srcRes:amount.
    
    for res in tgt:resources
    {
        if res:name = srcRes:name 
        {
            set tgtRes to res. 
        }
    }
    set finalAmt to Min(tgtRes:Capacity, tgtRes:Amount + xfrAmt).

    print "RESOURCE TRANSFER" at (0, g_line).
    print "-----------------" at (0, cr()).
    print "RESOURCE             : " + srcRes:name at (0, cr()).
    print "TRANSFER AMOUNT      : " + round(xfrAmt, 2) at (0, cr()).
    print "TRANSFER PROGRESS    : " + round(1 - (xfrAmt / tgtRes:amount), 2) * 100 + "%   " at (0, cr()).
    cr().
    print "SOURCE ELEMENT       : " + src:name at (0, cr()).
    print "SOURCE AMOUNT / CAP  : " + round(srcAmt, 2) + " / " + round(srcRes:Capacity, 1) at (0, cr()).
    cr().
    print "TARGET ELEMENT       : " + tgt:name at (0, cr()).
    print "TARGET AMOUNT / CAP  : " + round(tgtRes:amount, 2) + " / " + round(tgtRes:Capacity, 1) at (0, cr()).
    cr().
}

global function DispResTransfer2
{
    parameter src,
              srcRes,
              tgt,
              tgtRes,
              xfrAmt,
              srcBaseline,
              xfrStatus.

    set g_line to 10.


    local srcAmt to srcRes:amount.
    local srcCap to abs(srcRes:capacity).
    local srcPct to round(srcAmt / srcCap) * 100.

    local tgtAmt to tgtRes:amount.
    local tgtCap to abs(tgtRes:capacity).
    local tgtPct to round(tgtAmt / tgtCap) * 100.

    local resName to srcRes:name.
    local curAmt to abs(round(srcBaseline - srcAmt, 2)).
    local curPct to round(curAmt / xfrAmt) * 100.
    
    print "RESOURCE TRANSFER" at (0, g_line).
    print "-----------------" at (0, cr()).
    print "RESOURCE             : " + resName at (0, cr()).
    print "TRANSFER STATUS      : " + xfrStatus at (0, cr()).
    print "TRANSFER PROGRESS    : {0}/{1} ({2,3}%)":format(curAmt, xfrAmt, curPct) at (0, cr()).
    cr().
    print "SOURCE ELEMENT       : " + src:name at (0, cr()).
    print "SOURCE AMOUNT / CAP  : {0}/{1} ({2,3}%)":format(srcAmt, srcCap, srcPct) at (0, cr()).
    cr().
    print "TARGET ELEMENT       : " + tgt:name at (0, cr()).
    print "TARGET AMOUNT / CAP  : {0}/{1} ({2,3}%)":format(tgtAmt, tgtCap, tgtPct) at (0, cr()).
    cr().
}

local function DecToDegrees
{
    parameter _val.

    local denom to 360.
    set _val to mod(_val, denom).

    local degrees to floor(_val).
    local degMod to choose 1 if degrees = 0 else degrees.
    local minutes to mod(_val, degMod) / (1 / 60).
    local minMod to choose 1 if floor(minutes) = 0 else floor(minutes).
    local seconds to mod(minutes, minMod)/ (1 / 60). 
    set minutes to floor(minutes). 
    set seconds to floor(seconds).

    return "{0,3}{1} {2,2}{3} {4,2}{5}":format(degrees, char(176), floor(minutes), char(34), floor(seconds), char(39)).
}

// DispSci - Displays information pertaining to science experimentation
global function DispSci
{
    parameter _mode,
              _sciAction,
              _status,
              _biomeReport to list(list(),list()).

    set g_line to 10.

    local prntList to list(
        "MODE", _mode
        ,"SCI ACTION", _sciAction
        ,"",""
        ,"STATUS",    _status
        ,"SITUATION", ship:status
        ,"CUR BIOME", GetBiome()
        ,"LATITUDE",  DecToDegrees(ship:latitude)
        ,"LONGITUDE", DecToDegrees(ship:longitude)
    ).

    print "SCIENCE REPORT" at (0, g_line).
    print "--------------" at (0, cr()).

    if _mode = "biome"
    {
        prntList:add("").
        prntList:add("").
        prntList:add("REMAINING BIOMES").
        prntList:add("").
        for _b in _biomeReport[0]
        {
            prntList:add("-").
            prntList:add(_b). 
        }
        prntList:add("").
        prntList:add("").
        prntList:add("BIOMES RESEARCHED").
        prntList:add("").
        for _b in _biomeReport[1]
        {
            prntList:add("-").
            prntList:add(_b). 
        }
    }
    else if _mode = "full"
    {
        prntList:add("").
        prntList:add("").
        prntList:add("BIOMES RESEARCHED").
        prntList:add("").
        for _b in _biomeReport[0]
        {
            prntList:add("-").
            prntList:add(_b). 
        }
    }

    // print prntList at (2, 25).
    // Breakpoint().

    from { local labelIdx to 0. local valIdx to 1.} until labelIdx >= prntList:length step { set labelIdx to labelIdx + 2. set valIdx to valIdx + 2.} do
    {
        if prntList[labelIdx] = "" 
        {
            cr().
        }
        else if prntList[labelIdx] = "-"
        {
            print " {0} {1, -40}":format(prntList[labelIdx], prntList[valIdx]) at (0, cr()).
        }
        else
        {
            print "{0, -18}: {1, -40}":format(prntList[labelIdx], prntList[valIdx]) at (0, cr()).
        }
    }
}



// DispScope - Displays info about a telescope and it's target
global function DispScope
{
    set g_line to 10.

    local obtPeriod to TimeSpan(ship:orbit:period).

    print "SCOPE TELEMETRY" at (0, g_line).
    print "---------------" at (0, cr()).
    print "SCOPE    : " + ship:name at (0, cr()).
    print "BODY     : " + body:name at (0, cr()).
    print "ALT      : " + round(ship:altitude) at (0, cr()).
    print "AP       : " + round(ship:apoapsis) at (0, cr()).
    print "PE       : " + round(ship:periapsis) at (0, cr()).
    print "PER      : " + TimeSpan(mod(obtPeriod:seconds, ship:body:rotationperiod)):Full at (0, cr()).
    
    if HasTarget
    {
        cr().
        print "TARGET   : " + target:name at (0, cr()).
        print "DISTANCE : " + RoundDistance(Target:Position:Mag) + "      " at (0, cr()).
    }
    else
    {
        cr().
        clr(cr()).
        clr(cr()).
    }
}

// DispTargetData - Displays details about a provided vessel.
global function DispTargetData
{
    parameter _tgtVes.

    set g_line to 10.
    
    print "TARGET DATA" at (0, g_line).
    print "-----------" at (0, cr()).
    
    print "TARGET ORBITABLE     : " + _tgtVes:Name                                   at (0, cr()).
    print "REFERENCE BODY       : " + _tgtVes:Body:Name                              at (0, cr()).
    cr().
    print "ALTITUDE             : " + round(_tgtVes:Altitude)        + "m     "      at (0, cr()).
    print "APOAPSIS             : " + round(_tgtVes:Orbit:Apoapsis)  + "m     "      at (0, cr()).
    print "PERIAPSIS            : " + round(_tgtVes:Orbit:Periapsis) + "m     "      at (0, cr()).
    cr().
    print "DISTANCE             : " + round(_tgtVes:Position:Mag)    + "m     "      at (0, cr()).
    print "PHASE ANGLE          : " + round(kslib_nav_phase_angle(_tgtVes, Ship), 2) at (0, cr()).
}


// Pretty print functions
global function DispLex 
{
    parameter inObj, 
              tip is "PRETTY PRINT LEXICON".

    local stCol to 0.
    local stLine to 2.

    local numCols to 2.
    local lineLim to terminal:height - 5.
    local colSize to terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local maxKeyLen to 3.
    local maxValLen to 30.

    if tip = ""
    {
        if inObj:hasKey("<tip>") set tip to inObj["<tip>"]:replace("<tip>","").
    }

    local titleDiv to { local div to "". from { local i to 0.} until i = tip:length step { set i to i + 1.} do { set div to div + "-". } return div.}.            

    set g_col to stCol.
    set g_line to stLine.

    clearScreen. 
    
    for key in inObj:keys 
    {
        set maxKeyLen to max(maxKeyLen, key:tostring:length).
        set maxValLen to max(maxValLen, colSize - maxKeyLen - 5).
    }
    
    for key in inObj:keys
    {
        if g_line = stLine 
        {
                print tip at (g_col, g_line).
                print titleDiv:call() at (g_col, cr()).
                cr().
        }
        print "[{0,10}] [{1,-25}]":format(key, inObj[key]) at (g_col, g_line).
        
        if g_line < lineLim
        {
            set g_line to cr().
        } 
        else if g_col < colLim
        {
            set g_col to g_col + colSize.
            set g_line to stLine + 2.   
        }
        else
        {
            Breakpoint().
            clearScreen.
            set g_col to stCol.
            set g_line to stLine.
        }
    }
}

// Pretty-prints a list
global function DispList
{
    parameter inObj, 
              tip is "PRETTY PRINT LIST".

    local stCol to 0.
    local stLine to 2.

    local numCols to 2.
    local colSize to terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local lineLim to terminal:height - 5.

    local titleDiv to { local div to "". from { local i to 0.} until i = tip:length step { set i to i + 1.} do { set div to div + "-". } return div.}.    
    set g_col to stCol.
    set g_line to stLine.

    clearScreen. 

    from { local n is 0.} until n = inObj:length step { set n to n + 1.} do 
    {
        if g_line = stLine 
        {
                print tip at (g_col, g_line).
                print titleDiv:call() at (g_col, cr()).
                cr().
        }

        if g_line < lineLim
        {
            print "[{0,3}] [{1,-30}]  ":format(n, inObj[n]) at (g_col, g_line).
            set g_line to g_line + 1.
        } 
        else if g_col < colLim
        {
            set g_col to g_col + colSize.
            set g_line to stLine + 2.
            print "[{0,3}] [{1,-30}]  ":format(n, inObj[n]) at (g_col, g_line).
            set g_line to g_line + 1.
        } 
        else 
        {
            Breakpoint().
            clearScreen.
            set g_col to stCol.
            set g_line to stLine.
        }
    }
}

// DispPagedList :: <list>, [<str> UI Tip], [<int> itemsPerPage ] -> <none>
// Pages a list
global function DispPagedList
{
    parameter inList,
              uiTip is "Paged List",
              itemsPerPage is min(Terminal:Height - 12 - 5, 50). // Trimming 12 lines from the top, 5 from the bottom

    local curPage to list().
    local doneFlag to false.
    local pageIdx to 0.
    local pointer to 0.

    local pageCount to round(inList:length + 0.01 / itemsPerPage).

    until doneFlag
    {
        set pointer to pageIdx * itemsPerPage.
        set curPage to inList:sublist(pointer, itemsPerPage).
        DispList(curPage, "{0} [{1}/{2}]":format(uiTip, pageIdx, pageCount)).
        
    }
}