@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

DispMain(ScriptPath(), false).

// Declare Variables
local burnDir       to 0. // 0 for nothing, 1 for raising, -1 for lowering.
local burnETA       to 0.
local burnTS        to 0.
local checkDel      to 0.
local conditionType to "Ap".
local tgtVal        to Ship:Apoapsis.
local tgtVector     to Ship:Facing.

// Parse Params
if _params:length > 0 
{
  set tgtVector to type_to_vector(Ship, _params[0]). 
  if _params:Length > 1 set conditionType to _params[1].
  if _params:Length > 2 set tgtVal to _params[2].
  if _params:Length > 3 set burnETA to _params[3].
}

set t_Val to 0.
lock throttle to t_Val.

if conditionType = "Ecc"
{
    set burnTS to Time:Seconds + burnETA.

    local predictedVesPosition to PositionAt(ship, burnTS).
    local predictedVesOppoTaco to PositionAt(ship, burnTS + (Ship:Orbit:Period / 2)).
    local predictedBodyPosition to PositionAt(body, burnTS).
    local predictedBodyOppoTaco to PositionAt(body, burnTS + (Ship:Orbit:Period / 2)).
    local burnAlt to (predictedVesPosition - predictedBodyPosition) - Body:Radius.
    local curDiff to (predictedVesOppoTaco - predictedBodyOppoTaco) - Body:Radius.

    if tgtVal > 0
    {
        set tgtVal to GetApFromPeEcc(burnAlt, tgtVal).
    }
    else if tgtVal < 0
    {
        set tgtVal to GetPeFromApEcc(burnAlt, tgtVal).

        set burnDir to choose -1 if burnAlt > tgtVal else 1.
        if curVal > _tgtVal 
        { 
            set checkDel to { 
                parameter _ves, _tgtVal. 
                
                local curVal to (PositionAt(_ves, burnTS + (Ship:Orbit:Period / 2)) - Body:Position) - Body:Radius. 
                return curVal <= _tgtVal.
            }.
        } 
        else 
        {
            set checkDel to { 
                parameter _ves, _tgtVal. 
                
                local curVal to (PositionAt(_ves, burnTS + (Ship:Orbit:Period / 2)) - Body:Position) - Body:Radius. 
                return curVal > _tgtVal.
            }.
        } 
    }
}

set checkDel to (PositionAt(Ship, Time:Seconds + burnETA + (Ship:Orbit:Period / 2)) - Body:Position) - Body:Radius.


set curDv to NextNode:DeltaV:Mag.
set lastDv to NextNode:DeltaV:Mag + 0.1.
set g_tChar to "".
set doneflag to false.
until doneFlag {
  set curDv to NextNode:DeltaV:Mag.
  if vAng(Ship:Facing:Vector, Ship:Velocity:Orbit) < 23.5 {set tval to 1.} else {set tVal to 0.}
  if NextNode:DeltaV:Mag < 5 {set doneFlag to true.} else if Terminal:Input:HasChar {set g_tChar to Terminal:Input:GetChar.}
  if g_tChar:Length > 0 {
	if g_tChar = Terminal:Input:Enter {
	  set doneFlag to true.
    } else if g_tChar = char(43) {
	  warpTo(Time:Seconds + (60 * 60)).
	} else if g_tChar = char(61) {
	  warpTo(Time:Seconds + (15 * 60)).
	} 
	set g_tChar to "".
  } else if curDv > lastDv {
	set doneFlag to true.
  }
}
unlock throttle.
