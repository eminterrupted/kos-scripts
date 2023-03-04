// #include "0:/lib/loadDep.ks"
@lazyGlobal off.


// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local  os_ver         to "0.0.1a (ALPO)".
    local  TermWidth      to 70.
    local  TermHeight     to 50.
    
    // *- Global
    global g_col            to 0.
    global g_line           to 10.
    
// #endregion


// *~ Functions ~* //
// #region

    // *- Display micro functions -* //
    // #region

    // cr :: <none> -> <int> 
    // increments the global g_line variable by 1, and returns it.
    global function cr
    {
        set g_line to g_line + 1.
        return g_line.
    }


    // InitDisp :: <none> -> <none>
    // Sets the terminal resolution and brings it up
    global function InitDisp
    {
        parameter termW to TermWidth,
                  termH to TermHeight.

        set Terminal:Width to termW.
        set Terminal:Height to termH.
        if Core:HasEvent("Open Terminal") { Core:DoEvent("Open Terminal"). }
    }

    // OutMsg :: <string>String -> <none>
    // Writes a string in a consistent manner (location, formatting)
    global function OutMsg
    {
        parameter str is "".
                  
        local label to choose "[MSG]" if str:Length > 0 else "".
        if str:Length > Terminal:Width - 8
        {
            set str to str:Substring(0, Terminal:Width - 8).
        }
        else if str:Length < 1
        {
            set label to "".
        }
        print "{0,-6} {1, -60}":Format(label, str) at (0, 6).
    }

    // OutInfo :: <string>String, [<int>Position] -> <none>
    // Like OutMsg, prints a string, but with added flexibility of the pos parameter
    // pos is a positive offset from the default line it would be printed on if no value was passed
    global function OutInfo
    {
        parameter str is "",
                pos is 0.

        set pos to min(pos, 2).
        local label to "[INFO]".
        if str:Length > Terminal:width - 8
        {
            set str to str:substring(0, Terminal:width - 8).
        }
        else if str:Length < 1
        {
            set label to "".
        }

        print "{0,-6} {1, -60}":format(label, str) at (0, 7 + pos).
    }

    // OutInfo :: <string>String, [<int>Position] -> <none>
    // Like OutMsg, prints a string, but with added flexibility of the pos parameter
    // pos is a positive offset from the default line it would be printed on if no value was passed
    global function OutDebug
    {
        parameter str is "",
                  pos is 0.

        if g_DebugOut
        {
            local stLine to Terminal:Height - 15.
            set pos to min(pos, 2).
            local label to "[DEBUG]".
            if str:Length > Terminal:width - 8
            {
                set str to str:substring(0, Terminal:width - 8).
            }
            else if str:Length < 1
            {
                set label to "".
            }

            print "{0,-7} {1, -60}":format(label, str) at (0, stLine + pos).
        }
    }

    global function OutTee
    {
        parameter str is "",
                  errLvl is 0.
                  
        local hudLabel to "[INFO]".
        local hudColor to Green.
        local hudTime to 3.
        if errLvl > 0
        {
            if errLvl > 1 
            {
                set hudLabel to "[***ERROR***]".
                set hudColor to Red.
                set hudTime to 10.
            }
            else 
            {
                set hudLabel to "[*WARN*]".
                set hudColor to Yellow.
                set hudTime to 5.
            }
        }
        local termLabel to choose "[MSG]" if str:Length > 0 else "".
        if str:Length > Terminal:Width - 8
        {
            set str to str:Substring(0, Terminal:Width - 8).
        }
        else if str:Length < 1
        {
            set termLabel to "".
        }
        print "{0,-6} {1, -60}":Format(termLabel, str) at (0, 6).
        hudtext("{0}: {1}":Format(hudLabel, str), hudTime, 2, 20, hudColor, false).
    }

    // OutHUD :: 
    global function OutHUD 
    {
        parameter str,
                  errLvl is 0,
                  hudPos is 2,
                  screenTime is 10.

        local color to green.
        if errLvl = 1 set color to yellow.
        if errLvl = 2 set color to red.

        hudtext(str, screenTime, hudPos, 20, color, false).          
    }
    // #endregion



    // *- Main Display Blocks
    // #region

    // OutMain :: [<string>ScriptPath] -> none
    // Generates the header for the display
    global function DispMain
    {
        parameter _scrPath is "".

        print "KUSP Mission Assistant" at (0, 0).
                print "v: " + os_ver at (TermWidth - (os_ver:Length + 3), 0).
        from { local i to 0.} until i = TermWidth step { set i to i + 1.} do 
        {
            print "=" at (0 + i, 1).
        }
        print "MISSION  : {0}":format(ship:name) at (0, 2).
        print "MET      : {0}":format(TimeSpan(missionTime):full) at (0, 3).
        print "CURRENT PROGRAM  : {0}" :format(_scrPath) at (0, 4).
        //print "TAG DETAILS: [{0}][{1}]|[{2}]":format(g_tag[Core:part:uid + ":0"]:SCR, g_tag[Core:part:uid + ":0"]:PRM:Join(":"), g_stopStage) at (0, 5).
    }


    global function DispLaunchTelemetry
    {
        parameter _tgtAlt is -1.

        set g_line to 10.
        local label to "LAUNCH TELEMETRY".

        // if not exists(g_maxAlt) global g_maxAlt to 0.
        // set g_maxAlt to max(ship:Altitude, g_maxAlt).

        print "{0,-25}":format(label) at (0, g_line).
        cr().
        from { local i to 0.} until i = label:Length step { set i to i + 1.} do
        {
            print "-" at (0 + i, g_line).
        }

        print "ALTITUDE " at (1, cr()).
        if _tgtAlt > 0 print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (TGT)", round(_tgtAlt), "m") at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (MAX)", round(g_maxAlt), "m") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (CUR)", round(ship:Altitude), "m") at (2, cr()).
        cr().
        print "VELOCITY " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("SRF VELO (CUR)", round(ship:velocity:surface:mag, 2), "m/s") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("VERT SPD (CUR)", round(ship:verticalspeed, 2), "m/s") at (2, cr()).
        cr().
        print "TRAJECTORY " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("APOAPSIS", round(ship:Apoapsis), "m") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("APOAPSIS ETA", round(ship:orbit:eta:Apoapsis), "s") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("INCLINATION", round(ship:orbit:inclination, 3), char(176)) at (2, cr()).
        cr().
        print  "RESOURCES" at (1, cr()).
        local l_ConsumedResources to choose Round(100 * g_ConsumedResources["PctRemaining"]) if g_ConsumedResources:HasKey("PctRemaining") else "NA".
        print "|- {0,-15}: {1}{2}   ":format("RESOURCE REMAINING", l_ConsumedResources, "%") at (2, cr()).
        local l_TimeToResDepletion to choose Round(g_ConsumedResources["TimeRemaining"], 2) if g_ConsumedResources:HasKey("TimeRemaining") else "NA".
        print "|- {0,-15}: {1}{2}   ":format("TIME TO DEPLETION", l_TimeToResDepletion, "s") at (2, cr()).
        if g_HotStageArmed
        {
            cr().
            print "HOT STAGING" at (1, cr()).
            print "|- {0, -15}: {1}{2}   ":format("TIME TO STAGING", round(g_TS - Time:Seconds, 2), "s") at (2, cr()).
        }
        // print "ENGINES " at (1, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("THRUST (CUR)", round(g_activeEngines["CURTHRUST"], 2), "kn") at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("THRUST (AVL)", round(g_activeEngines["AVLTHRUST"], 2), "kn") at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("THRUST (% CUR)", round( (max(0.00001, g_activeEngines["CURTHRUST"]) / max(0.00001, g_activeEngines["AVLTHRUST"] ) * 100)), "%") at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("TWR    (CUR)", round( g_activeEngines["TWR"], 2)) at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("TWR    (AVL)", round( g_activeEngines["AvailTWR"], 2)) at (2, cr()).

        // cr().
        // if _prmList:Length > 0 
        // {
        //     print " MISC " at (0, cr()).
        //     print " |- {0, -15}: {1}{2}   ":format(_prmList[0], _prmList[1], _prmList[2]) at (0, cr()).
        // }
        // else
        // {
        //     print "{0,72}":format(" ") at (0, cr()).
        // }
    }


    global function DispEngineTelemetry
    {
        parameter _engs is GetActiveEngines().

        set g_line to 10.
        
        local label to "ENGINE PERFORMANCE".
        local engPerfData to GetEngineData(_engs).

        print "{0, -25}":format(label) at (0, g_line).
        cr().
        from { local i to 0.} until i = label:Length step { set i to i + 1.} do
        {
            print "-" at (0 + i, g_line).
        }
        
        print "{0, -25}":format("ENGINE TELEMETRY") at (0, g_line).
        print " |- {0, -16}: {1}{2}   ":format("ENG THRUST", round(engPerfData:CURTHRUST, 2), "kn") at (0, cr()).
        print " |- {0, -16}: {1}{2}   ":format("ENG AVL THRUST", round(engPerfData:AVLTHRUST, 2), "kn") at (0, cr()).
        print " |- {0, -16}: {1}{2}   ":format("ENG THRUST %", round( (max(0.00001, engPerfData:CURTHRUST) / max(0.00001, engPerfData:AVLTHRUST ) * 100)), "%") at (0, cr()).
    }

    // OutScriptFlags
    global function OutScriptFlags
    {
        // local activeFlags to lex().
        local _ln to 30.

        print g_scriptFlags at (2, 40).
        if g_scriptFlags:keys:Length > 0
        {
            from { local idx to 0.} until idx = g_scriptFlags:keys:Length step { set idx to idx + 1.} do
            {
                local flagID to g_scriptFlags:keys[idx].
                if flagID = "Ref"
                {
                }
                else
                {
                    OutInfo("flagID: [{0}]":format(flagID), 1).
                    print "*** flagID: [{0}]":format(flagID) at (50, 5).
                    print "[{0}] ({1}) {2} ":format(flagID, g_scriptFlags["Ref"][flagID], true) at (4, _ln + idx).
                }
            }
        }
    }


    // DispData :: [<lexicon>Object to print, <int>line]
    global function DispTelemetry
    {
        parameter _dispData,
                  _dispLine is 10.

        if _dispData:IsType("Lexicon")
        {
            if _dispData:Keys:Length > 0
            {
                set g_line to _dispLine.

                DispHeaderLine(_dispData:Keys[0], _dispData:Values[0]).

                from { local iKey to 1.} until iKey = _dispData:Keys:Length step { set iKey to iKey + 1.} do
                {
                    if _dispData:Keys[iKey]:MatchesPattern("^CR_.*")
                    {
                        cr().
                    }
                    else
                    {
                        print "- {0, -15}: {1, -40}":Format(_dispData:Keys[iKey], _dispData:Values[iKey]) at (0, cr()).
                    }
                }
                
            }
        }
    }

    // DispHeaderLine :: [<string>Header text, <int>Line, <string>Header character]
    local function DispHeaderLine
    {
        parameter _hdrText,
                  _hdrChar,
                  _hdrLine is g_line,
                  _hdrCol is 0.

        set g_line to _hdrLine.

        print _hdrText at (_hdrCol, g_line).
        cr().
        from { local i to 0.} until i = _hdrText:Length step { set i to i + 1.} do
        {
            print _hdrChar at (_hdrCol + i, g_line).
        }
        cr().
    }

    // DispClr :: [<scalar>Line To start, <scalar>Line to stop]
    // Clears a display block
    global function DispClr
    {
        parameter line_start to 10, 
                  line_end   to Terminal:height - 2.

        local clrLine to "{0," + (Terminal:width - 1) + "}".
        set clrLine to clrLine:format(" ").
        from { local i to line_start.} until i = line_end step { set i to i + 1.} do
        {
            print clrLine at (0, i).
        }
    }

    

local function PrettyPrintObject
{
    parameter _obj.

    if _obj:IsType("Lexicon") 
    {
        for k in _obj:keys
        {
            OutInfo("Key: {0}   Value: {1}":format(k, _obj[k])).
            BreakPoint().
        }
    }
    else if _obj:IsType("List")
    {
        for k in _obj
        {
            OutInfo("Item: {0}":format(k)).
            Breakpoint().
        }
    }
}



    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    // #endregion
// #endregion