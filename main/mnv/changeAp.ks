@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local stAp to Ship:Apoapsis.
local stPe to Ship:Periapsis.

local tgtAp to 0.
local tgtUT to Time:Seconds + ETA:Periapsis.

// Parse Params
if _params:length > 0 
{
  set tgtAp to ParseStringScalar(_params[0], tgtAp).
  if _params:length > 1 set tgtUT to ParseStringScalar(_params[1], tgtUT).
}

OutMsg("ChangeAp").
if HasNode remove NextNode.
cr().
wait 0.25.
OutInfo("Input Parameters: ").
local iLex to lex("tgtAp", tgtAp, "tgtUT", tgtUT, "ETA", Timespan(tgtUT - Time:Seconds):Full).
for key in iLex:Keys
{
    OutInfo("|- {0,-5}: {1}":Format(key, iLex[key])).
}
cr().

if tgtAp < Ship:Periapsis
{
    OutMsg("ERR: tgtAp [{0}] below Pe [{1}]":Format(tgtAp, Round(Ship:Periapsis))).
    Breakpoint("baby, what are you doin?").
}
else
{
    OutMsg("Beginning node calculations").
    OutInfo("Checking maneuver node creation capabilities: [{0}]":Format(Career():CanMakeNodes)).
    // TgtPe
    if Career():CanMakeNodes
    {
        set stPe to Body:AltitudeOf(PositionAt(Ship, tgtUT)).
        set stAp to Body:AltitudeOf(PositionAt(Ship, tgtUT + Ship:Orbit:Period / 2)).
    }

    OutInfo("Using starting values:").
    OutInfo("|- stPe: {0}":Format(stPe)).
    OutInfo("|- stAp: {0}":Format(stAp)).
    cr().
    
    local choiceStr to "A/B/C".
    local doneFlag to false.
    local goFlag to false.
    local dvList to list().
    local dvToUse to 0.
    local _line to g_Line.
    local selStr to "".

    local dvNeededBE   to CalcDvBE(stPe, stAp, stPe, tgtAp, tgtAp, "pe").
    local dvNeededHoH  to CalcDvHoh(stPe, stAp, tgtAp).
    local dvNeededHoH2 to CalcDvHoh2(stPe, stAp, stPe, tgtAp, Ship:Body).

    local beStr to "1: BE [A:{0}] [B:{1}] [C:{2}] (m/s)":Format(Round(dvNeededBE[0], 2), Round(dvNeededBE[1], 2), Round(dvNeededBE[2], 2)).
    local hoStr to "2: HO [A:{0}] [B:{1}] (m/s)":Format(Round(dvNeededHoh[0], 2), Round(dvNeededHoh[1], 2)).
    local h2Str to "3: H2 [A:{0}] [B:{1}] (m/s)":Format(Round(dvNeededHoh2[0], 2), Round(dvNeededHoh2[1], 2)).

    set g_TermChar to "".

    until doneFlag
    {
        set g_Line to _line.
        
        GetTermChar().

        if doneFlag
        {
            if g_TermChar = Terminal:Input:Enter
            {
                clr(cr()).
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set doneFlag to false.
                set goFlag to false.
                set dvList to list().
                set dvToUse to 0.
                clr(cr()).
            }
            OutInfo("Confirm: ENTER | Back: DELETE").
        }
        else if goFlag
        {
            OutInfo(selStr).
            clr(cr()).
            clr(cr()).
            clr(cr()).
            OutMsg("Select DV Value [{0}]":Format(choiceStr)).
            clr(cr()).

            set dvToUse to 0.
            
            if g_TermChar:MatchesPattern("(a|A)")
            {
                OutInfo("Select: A [{0}m/s]":Format(dvList[0])).
                set dvToUse to dvList[0].
                set doneFlag to true.
            }
            else if g_TermChar:MatchesPattern("(b|B)")
            {
                OutInfo("Select: B [{0}m/s]":Format(dvList[1])).
                set dvToUse to dvList[1].
                set doneFlag to true.
            }
            else if g_TermChar:MatchesPattern("(c|C)") and choiceStr:Contains("C")
            {
                OutInfo("Select: C [{0}m/s]":Format(dvList[2])).
                set dvToUse to dvList[2].
                set doneFlag to true.
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                clr(cr()).
                set goFlag to false.
                set dvList to list().
                set dvToUse to 0.
            }
            else
            {
                OutInfo("Select: ").
            }
        }
        else
        {
            if g_TermChar:MatchesPattern("(1)")
            {
                OutInfo(beStr).
                set selStr to beStr.
                set choiceStr to choose choiceStr if choiceStr:Contains("/C") else choiceStr + "/C".
                set dvList to dvNeededBE.
                set goFlag to true.
            }
            else if g_TermChar:MatchesPattern("(2)")
            {
                OutInfo(hoStr).
                set selStr to hoStr.
                set choiceStr to choiceStr:Replace("/C","").
                set dvList to dvNeededHoH.
                set goFlag to true.
            }
            else if g_TermChar:MatchesPattern("(3)")
            {
                OutInfo(h2Str).
                set selStr to h2Str.
                set choiceStr to choiceStr:Replace("/C","").
                set dvList to dvNeededHoH2.
                set goFlag to true.
            }
            else
            {
                OutInfo(beStr).
                OutInfo(hoStr).
                OutInfo(h2Str).
                clr(cr()).
                OutMsg("Select DV Type [1/2/3]").
            }
        }
        set g_TermChar to "".
    }

    local circNode to node(tgtUT, 0, 0, dvToUse).
    add circNode.
    wait 0.25.
    wait 0.25.

    clearScreen.
    ExecNodeBurn(circNode).
}