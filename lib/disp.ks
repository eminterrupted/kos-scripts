// #include "0:/lib/loadDep.ks"
@lazyGlobal off.


// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local os_ver            to "0.0.1a (ALPO)".
    
    // *- Global
    global g_col            to 0.
    global g_line           to 8.
    global g_tChar          to "".
    global g_termWidth      to 72.
    global g_termHeight     to 60.
    
// #endregion


// *~ Functions ~* //
// #region

    // *- Display micro functions -* //
    // #region
    global function cr
    {
        set g_line to g_line + 1.
        return g_line.
    }

    global function InitDisp
    {
        set terminal:width to g_termWidth.
        set terminal:height to g_termHeight.
        core:doEvent("Open Terminal").
    }

    global function OutMsg
    {
        parameter str.

        local label to choose "[MSG]" if str:length > 0 else "".
        if str:length > terminal:width - 8
        {
            set str to str:substring(0, terminal:width - 8).
        }
        else if str:length < 1
        {
            set label to "".
        }
        print "{0,-6} {1, -60}":format(label, str) at (0, 6).
    }

    global function OutInfo
    {
        parameter str is "",
                pos is 0.

        set pos to max(pos, 1).
        local label to "[INFO]".
        if str:length > terminal:width - 8
        {
            set str to str:substring(0, terminal:width - 8).
        }
        else if str:length < 1
        {
            set label to "".
        }

        print "{0,-6} {1, -60}":format(label, str) at (0, 7 + pos).
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
                print "v: " + os_ver at (g_termWidth - (os_ver:length + 3), 0).
        from { local i to 0.} until i = g_termWidth step { set i to i + 1.} do 
        {
            print "=" at (0 + i, 1).
        }
        print "MISSION  : {0}":format(ship:name) at (0, 2).
        print "MET      : {0}":format(TimeSpan(missionTime):full) at (0, 3).
        print "CURRENT PROGRAM  : {0}" :format(_scrPath) at (0, 4).
        //print "TAG DETAILS: [{0}][{1}]|[{2}]":format(g_tag[core:part:uid + ":0"]:SCR, g_tag[core:part:uid + ":0"]:PRM:Join(":"), g_stopStage) at (0, 5).
    }


    global function DispLaunchTelemetry
    {
        parameter _prmList is list(body:atm:height).

        set g_line to 10.
        local label to "LAUNCH TELEMETRY".

        if not exists(g_maxAlt) global g_maxAlt to 0.
        set g_maxAlt to max(ship:altitude, g_maxAlt).

        print "{0,-25}":format(label) at (0, g_line).
        cr().
        from { local i to 0.} until i = label:length step { set i to i + 1.} do
        {
            print "-" at (0 + i, g_line).
        }

        print "ALTITUDE " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (TGT)", round(_prmList[0]), "m") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (MAX)", round(g_maxAlt), "m") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("ALTITUDE (CUR)", round(ship:altitude), "m") at (2, cr()).
        cr().
        print "VELOCITY " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("SRF VELO (CUR)", round(ship:velocity:surface:mag, 2), "m/s") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("VERT SPD (CUR)", round(ship:verticalspeed, 2), "m/s") at (2, cr()).
        cr().
        print "TRAJECTORY " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("APOAPSIS", round(ship:apoapsis), "m") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("APOAPSIS ETA", round(ship:orbit:eta:apoapsis), "s") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("INCLINATION", round(ship:orbit:inclination, 3), char(176)) at (2, cr()).
        cr().
        print "ENGINES " at (1, cr()).
        print "|- {0,-15}: {1}{2}   ":format("THRUST (CUR)", round(g_activeEngines["CURTHRUST"], 2), "kn") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("THRUST (AVL)", round(g_activeEngines["AVLTHRUST"], 2), "kn") at (2, cr()).
        print "|- {0,-15}: {1}{2}   ":format("THRUST (% CUR)", round( (max(0.00001, g_activeEngines["CURTHRUST"]) / max(0.00001, g_activeEngines["AVLTHRUST"] ) * 100)), "%") at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("TWR    (CUR)", round( g_activeEngines["TWR"], 2)) at (2, cr()).
        // print "|- {0,-15}: {1}{2}   ":format("TWR    (AVL)", round( g_activeEngines["AvailTWR"], 2)) at (2, cr()).

        // cr().
        // if _prmList:length > 0 
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
        parameter _engs is g_activeEngines.

        set g_line to 10.
        
        local label to "ENGINE PERFORMANCE".
        local engPerfData to GetEnginePerfData(_engs).

        print "{0, -25}":format(label) at (0, g_line).
        cr().
        from { local i to 0.} until i = label:length step { set i to i + 1.} do
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
        if g_scriptFlags:keys:length > 0
        {
            from { local idx to 0.} until idx = g_scriptFlags:keys:length step { set idx to idx + 1.} do
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


    // DispClr :: [<scalar>Line To start, <scalar>Line to stop]
    // Clears a display block
    global function DispClr
    {
        parameter line_start to 10, 
                  line_end   to terminal:height.

        local clrLine to "{0," + terminal:width + "}".
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