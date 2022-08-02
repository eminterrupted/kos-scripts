@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").

DispMain(scriptPath()).

local tgtBody to Body.

if params:length > 0 
{
    set tgtBody to params[0].
}

OutMsg("Searching for intercept patch").

set ship:control:pilotmainthrottle to 0.
unlock steering.
unlock throttle.

local iPatch    to ship:orbit.
local iPatchIdx to -1.
until false
{
    set iPatchIdx to GetInterceptPatchIndex(tgtBody).
    if iPatchIdx >= 0 
    {
        set iPatch to GetPatchByIndex(iPatchIdx).
        OutMsg("Intercept detected in patch " + iPatchIdx).
        break.
    }
    DispOrbit().
}

if iPatch:Body = tgtBody
{
    OutMsg("Intercept confirmed at patch index " + iPatchIdx).
}
else
{
    OutTee("Intercept detected but not confirmed!", 1, 2).
}