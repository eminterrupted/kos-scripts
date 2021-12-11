@lazyGlobal off.
clearScreen.

parameter val is 0.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

// OutMsg("Waiting for burn...").

// until GetTotalThrust(GetEngines("active")) > 0.1
// {
//     DispOrbit().
// }

// local stLng to ship:longitude.
// OutMsg("Burn started").
// OutInfo("Starting longitude: " + round(stLng, 3)).

// until GetTotalThrust(GetEngines("active")) < 0.1
// {
//     DispOrbit().
// }

// local endLng to ship:longitude.
// local dLng to endLng - stLng.

// OutMsg("Burn complete").
// OutInfo2("Ending longitude: " + round(endLng, 3)).
// wait 1.
// OutInfo2().
// OutInfo("Longitude Delta: " + round(dLng, 3)).
OutMsg("Measuring degrees / sec").
local degSec to ship:longitude.
wait 5.
set degSec to abs(ship:longitude - degSec) / 5.
local secsDeg to 1 / degSec.

lock valDiff to abs(mod(360 + val - ship:longitude, 360)).
local warpSecs to valDiff * secsDeg.
OutInfo("Degree travel time (s): " + round(secsDeg, 3)).
OutInfo2("warpSecs: " + round(warpSecs, 1)).
InitWarp(time:seconds + warpSecs).
print "valDiff: " + round(valDiff, 3) at (2, 10).
Breakpoint().
OutMsg("Waiting for longitude").
until CheckValRange(ship:longitude, val - 2.5, val + 2.5)
{
    DispOrbit().
    OutInfo("Current LNG: " + round(ship:longitude, 3)).
    OutInfo2("Target LNG : " + round(val, 3)).
}
set warp to 0.
Breakpoint().
if not hasNode 
{
    local testNode to node(0, 0, 0, 0).
    add testNode.
}
runPath("0:/util/execNode").
Breakpoint().
if not hasNode 
{
    local testNode to node(0, 0, 0, 0).
    add testNode.
}
runPath("0:/util/execNode").