@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/lib/deploader").
runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/module").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/engine").

InitTerm(true, true, true).

// Declare Variables
local dirComponents to compass_and_pitch_for(Ship, Ship:Facing:ForeVector).
local launchAng to dirComponents[1].
local launchHdg to dirComponents[0].

// Parse Params
if _params:length > 0 
{
  set launchHdg to _params[0].
  if _params:Length > 1 set launchAng to _params[1].
}

// Setup terminal display


// Setup initial control environment
local sVal to Ship:Facing.
local tVal to 0.

// #TODO: Setup countdown
local cdTimer to 5.

local padStage to { local minStage to Stage:Number. for p in Ship:PartsNamedPattern("AM.MLP.*") { set minStage to min(minStage, p:Stage). } return minStage.}.

// -- Get spool time for engines in launch stage
local stgEngs to GetBurnStageEngines(Ship, padStage + 1, true).
local maxSpool to 0.
from { local i to stgEngs:Length - 1.} until i < 0 step { set i to i - 1.} do
{
    local eng to stgEngs[i].
    local m to eng:GetModule("ModuleEnginesRF").
    local fldStr to "effective spool-up time".

    if not m:HasField(fldStr)
    {
        stgEngs:Remove(i).
    }
    else
    {
        set maxSpool to max(maxSpool, m:GetField(fldStr)).
    }
}
set cdTimer to cdTimer + Round(maxSpool).

// #TODO: Confirm launch go

// #TODO: Execute countdown

// #TODO: Ignite engines

// #TODO: Evaluate launch conditions

// #TODO: Liftoff

// #TODO: Vertical Ascent

// #TODO: Coast