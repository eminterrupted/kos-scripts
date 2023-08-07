@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath()).

local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, Ship:Apoapsis, Ship:Apoapsis, Ship:Apoapsis).
// local dvNeeded to CalcDvHoh(Ship:Periapsis, Ship:Apoapsis, Ship:Apoapsis).
OutMsg("Calculated DV Needed: {0}":Format(Round(dvNeeded[1], 2))).

local circNode to Node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).
wait 1.

until not hasNode
{
    remove nextNode. 
}
add circNode.
ExecNodeBurn(circNode).

OutMsg("Maneuver complete").
wait 1.