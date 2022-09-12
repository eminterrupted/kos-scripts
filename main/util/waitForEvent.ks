@LazyGlobal off.
ClearScreen.

parameter params is list(). 
          
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath()).

local event to "".
local value to "".

if params:length > 0 
{
    set event to params[0].
    if params:length > 1 set value to params[1].
}

OutMsg("Waiting for event: " + event).
OutInfo("Expected value: " + value).

if event = "sciAlt"
{
    if value = "high" 
    {
        until ship:altitude >= BodyInfo:altForSci:Moho
        {
            DispOrbit().
        }
    }
    else if value = "low"
    {
        until ship:altitude <= BodyInfo:altForSci:Moho
        {
            DispOrbit().
        }
    }
}

OutMsg("Event detected!").
OutInfo().
wait 1.
OutMsg().