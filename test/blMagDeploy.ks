@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").

set g_MainProc to ScriptPath().
DispMain().

local tgtList to list().
local tgtPart to "".
local tgtTag  to "".

if params:Length > 0
{
    if params[0]:IsType("list")
    {
        set tgtList to params[0].
    }
    else if params[0]:IsType("Part")
    {
        set tgtPart to params[0].
    }
    else
    {
        set tgtTag to params[0].
    }
}

if tgtTag:Length > 0
{
    set tgtList to Ship:PartsTaggedPattern(tgtTag).
}
else if tgtPart:IsType("Part")
{
    set tgtList to list(tgtPart).
}
