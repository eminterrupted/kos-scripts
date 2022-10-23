@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/disp").
RunOncePath("0:/lib/util").
DispMain(ScriptPath()).

local holdTime to 0.
local liftTime to time:seconds.
local startTime to time:seconds.
local waitFor to 0.
if params:length > 0 
{
    set waitFor to choose params[0] if params[0]:isType("Scalar") else params[0]:ToNumber(0).
}
set liftTime to time:seconds + waitFor.

OutMsg("Script execution hold. Press Enter to continue.").
until false
{
    set holdTime to time:seconds - startTime.
    OutInfo("Current hold time: " + (TimeSpan(holdTime):full):ToString).
    if CheckInputChar(Terminal:Input:Enter)
    {
        break.
    }
    if waitFor > 0 
    {
        OutInfo2("Wait remaining: " + (TimeSpan(time:seconds - liftTime):full):ToString).
        if time:seconds >= liftTime 
        {
            break.
        }
    }
    wait 0.1.
}