@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/burnCalc").

DispMain(ScriptPath():name).

// Declare Variables
local tgtVes to "".
local timeInterval to 60.

// Parse Params
if params:length > 0 
{
  set tgtVes to params[0].
}

// Assumption: match velocities at closest approach
// Relative velocity to target: ship:orbit:velocity:orbit:mag - target:orbit:velocity:orbit:mag
local ts to time:seconds.
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
lock vel_Diff_Vector    to vel_Tgt_TS - vel_Us_TS.
lock burn_unit          to Target:retrograde:vector:normalized.

global function PredictedObtNormal
{
    parameter _tgt, 
              _ts.

    local _tgtObt to OrbitAt(_tgt, _ts).
    return vcrs( _tgtObt:body:position - _tgtObt:position, _tgtObt:velocity:orbit):normalized.
}

lock vel_Diff_Tangent_TS  to vel_Diff_Vector:normalized.
lock vel_Diff_Normal_TS   to vcrs(pos_Tgt_TS - velocityAt(ship:body, ts):orbit, vel_Diff_Tangent_TS):normalized.
lock vel_Diff_Radial_TS   to vcrs(vel_Diff_Normal_TS, vel_Diff_Tangent_TS):normalized.

// lock obt_Us_TS          to orbitAt(ship, ts).
// lock obt_Tgt_TS         to orbitAt(tgtVes, ts).

until not hasNode
{
    if hasNode remove nextNode.
    wait 0.01.
}

local _dList to list().

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
        set _dList to list(
            "Searching for Closest Approach...", ""
            ,"ETA",                 TimeSpan(ts - time:seconds):full
            ,"Approach Altitude",   round(abs((pos_Us_TS - positionAt(ship:body, ts)):mag) - ship:body:radius)
            ,"Distance To Target",  round(pos_Dist_Diff, 1)
            ,"Relative Velocity",   round(vel_Diff_Vector:mag)
        ).

        wait 0.01.
        DispGeneric(_dList, 12).
    }
}
// Normals
local ves_nrm to PredictedObtNormal(ship, ts).
local tgt_nrm to PredictedObtNormal(tgtVes, ts).

// Total inclination change
local d_inc to vang(ves_nrm, tgt_nrm).

// Get deltav / burnvector magnitude
local burn_mag to -2 * vel_Us_TS:mag * cos(vang(vel_Us_TS, burn_unit)).

// Get the dV components for creating the node structure
local burn_nrm to burn_mag * cos(d_inc / 2).
local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).
local burn_rad to (burn_mag ^ 2) / abs((pos_Tgt_TS - positionAt(tgtVes:body, ts)):mag).

OutMsg("Adding node!").
local mnvNode to node(ts, burn_rad, burn_nrm, burn_pro).
add mnvNode.
wait 0.01.

ExecNodeBurn(nextNode).
wait 0.01.
OutMsg("All done!").
