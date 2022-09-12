@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/loadDep").

local theseCams to "all".

if params:length > 0
{
    set theseCams to params[0].
}

local camsOnVes to ship:modulesNamed("ModuleNeptuneCamera").

if theseCams = "fc" or theseCams = "color" or theseCams = "all"
{
    SnapPic("capture full colour image").
    OutMsg("Neptune image captured: Full Color").
}
wait 0.01.

if theseCams = "gs" or theseCams = "grey" or theseCams = "greyscale" or theseCams = "all"
{   
    SnapPic("capture greyscale image").
    OutMsg("Neptune image captured: Greyscale").
}
wait 0.01.

if theseCams = "rgb" or theseCams = "all"
{
    SnapPic("capture red image").
    wait 0.01.
    SnapPic("capture green image").
    wait 0.01.
    SnapPic("capture blue image").
    OutMsg("Neptune image captured: RGB").
}
wait 0.01.

if theseCams = "ir" or theseCams = "infrared" or theseCams = "all"
{
    SnapPic("capture infrared image").
    OutMsg("Neptune image captured: Infrared").
}
wait 0.01.

if theseCams = "uv" or theseCams = "ultraviolet" or theseCams = "all"
{
    SnapPic("capture ultraviolet image").
    OutMsg("Neptune image captured: Ultraviolet").
}
wait 0.01.



///////////////
local function SnapPic
{
    parameter event.

    for c in camsOnVes
    {
        if c:hasEvent(event) DoEvent(c, event).
    }
}