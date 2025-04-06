@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

DispMain(ScriptPath(), false).

// Declare Variables
local showMain  to false.
local showPilot to false.
local showTrim  to false.

// Parse Params
for _p in _params
{
    if _p = "main" 
    {
        set showMain to true.
    }
    else if _p = "pilot"
    {
        set showPilot to true.
    }
    else if _p = "trim"
    {
        set showTrim to true.
    }
}

until false
{
    local dispObj to lexicon().
    if showMain dispObj:Add("MAIN", list()).
    if showPilot dispObj:Add("PILOT", list()).
    if showtrim dispObj:Add("TRIM", list()).

    from { local i to 0.} until i = _params:length step { set i to i + 1.} do
    {
        local dispKey to dispObj:Keys[i].
        
        if dispKey = "main"
        {
            dispObj:MAIN:Add("MAIN OUTPUT").
            dispObj:MAIN:Add("{0}: {1} ":Format("Pitch",         Round(Ship:Control:Pitch, 2))).
            dispObj:MAIN:Add("{0}: {1} ":Format("Yaw",           Round(Ship:Control:Yaw, 2))).
            dispObj:MAIN:Add("{0}: {1} ":Format("Roll",          Round(Ship:Control:Roll, 2))).
            dispObj:MAIN:Add("{0}: {1} ":Format("Fore",          Round(Ship:Control:Fore, 2))).
            dispObj:MAIN:Add("{0}: {1} ":Format("Top",            Round(Ship:Control:Top, 2))).
            dispObj:MAIN:Add("{0}: {1} ":Format("Starboard",     Round(Ship:Control:Starboard, 2))).
            dispObj:MAIN:Add("{0}: {1,-5} ":Format("MainThrottle",  Round(Ship:Control:MainThrottle, 2))).
        }
        else if dispKey = "pilot"
        {
            dispObj:PILOT:Add("PILOT INPUT").
            dispObj:PILOT:Add("{0}: {1} ":Format("Pitch", Round(Ship:Control:PILOTPITCH, 2))).
            dispObj:PILOT:Add("{0}: {1} ":Format("Yaw", Round(Ship:Control:PILOTYAW, 2))).
            dispObj:PILOT:Add("{0}: {1} ":Format("Roll", Round(Ship:Control:PILOTROLL, 2))).
            dispObj:PILOT:Add("{0}: {1} ":Format("Fore", Round(Ship:Control:PILOTFORE, 2))).
            dispObj:PILOT:Add("{0}: {1} ":Format("Top", Round(Ship:Control:PILOTTOP, 2))).
            dispObj:PILOT:Add("{0}: {1} ":Format("Starboard", Round(Ship:Control:PILOTSTARBOARD, 2))).
            dispObj:PILOT:Add("{0}: {1,-5} ":Format("Mainthrottle", Round(Ship:Control:PILOTMAINTHROTTLE, 2))).
        }
        else if dispKey = "trim"
        {
            set showTrim to true.
        }

        DispPrintBlock(i, dispObj[dispKey]).
    }
}