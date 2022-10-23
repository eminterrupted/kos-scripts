@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/mnv").

DispMain(ScriptPath():name).

// Declare Variables
local tgtVes to "".
local timeInterval to 1.

// Parse Params
if params:length > 0 
{
  set tgtVes to params[0].
}

// Assumption: match velocities at closest approach
// Relative velocity to target: ship:orbit:velocity:orbit:mag - target:orbit:velocity:orbit:mag
local ts to ts + timeInterval.
local tsNext to ts + timeInterval.

lock pos_Us_TS          to positionAt(ship, ts).
lock pos_Tgt_TS         to positionAt(tgtVes, ts).
lock pos_Us_TSNext      to positionAt(ship, tsNext).
lock pos_Tgt_TSNext     to positionAt(tgtVes, tsNext).

lock pos_Dist_TS        to (pos_Us_TS - pos_Tgt_TS):mag.
lock pos_Dist_TSNext    to (pos_Us_TSNext - pos_Tgt_TSNext):mag.
lock pos_Dist_Diff      to pos_Dist_TS - pos_Dist_TSNext.

lock vel_Us_TS          to velocityAt(ship, ts):orbit.
lock vel_Tgt_TS         to velocityAt(tgtVes, ts):orbit.
lock vel_Diff_Vector    to vel_Us_TS - vel_Tgt_TS.

lock vel_Diff_Prograde  to vxcl(ship:body:north:vector, vel_diff_vector).
lock vel_Diff_Normal    to vcrs(pos_Us_TS - positionAt(ship:body, ts), vel_Diff_Prograde).
lock vel_Diff_Radial    to vcrs(vel_Diff_Normal, vel_Diff_Prograde).

lock obt_Us_TS          to orbitAt(ship, ts).
lock obt_Tgt_TS         to orbitAt(tgtVes, ts).

until not hasNode
{
    if hasNode remove nextNode.
    wait 0.01.
}

OutMsg("Calculating future positions").
// Loop Result: Closest approach is 'ts'
until false
{
    set ts to ts + timeInterval.
    set tsNext to ts + timeInterval.

    if pos_Dist_TS <= pos_Dist_TSNext 
    {
        break.
    }
    else
    {
        local dispList to list(
            "Searching for Closest Approach..."
            ,"ETA",                 TimeSpan(ts - time:seconds):full
            ,"Approach Altitude",   round(abs((pos_Us_TS - positionAt(ship:body, ts)):mag) - ship:body:radius)
            ,"Distance To Target",  round(pos_Dist_Diff, 1)
            ,"Relative Velocity",   round(vel_Diff_Vector:mag)
        ).

        DispGeneric(dispList, 12).
    }
}

OutMsg("Adding node!").
local mnvNode to node(ts, -(vel_Diff_Radial), vel_Diff_Normal, vel_Diff_Prograde ).
add mnvNode.
wait 0.01.

ExecNodeBurn(nextNode).
wait 0.01.
OutMsg("All done!").