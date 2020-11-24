@lazyGlobal off.

parameter tgt.

runOncePath("0:/kslib/library/lib_navigation").
runOncePath("0:/lib/data/nav/lib_deltav").
runOncePath("0:/lib/data/nav/lib_nav").

set target to tgt.

//Semi major axis calculations
local cSMA to (ship:apoapsis + ship:periapsis + (body:radius * 2)) / 2. //Current
local tSMA to target:altitude + body:radius.                            //Target

//Hohman SMA calculation
local hSMA to (cSMA + tSMA)  / 2.

//Phase angle
local rPhase to (1 / (2 * sqrt(tSMA ^ 3 / hSMA ^ 3))) * 360.



//Get the phase angle to target.
lock tgtPhase to phaseAngle().
