@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath()).

local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, Ship:Apoapsis, Ship:Apoapsis, Ship:Apoapsis).
OutMsg("Calculated DV Needed: {0}":Format(Round(dvNeeded, 2))).

local circNode to Node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded).
wait 5.

ExecNodeBurn(circNode).

OutMsg("Maneuver complete").
wait 1.