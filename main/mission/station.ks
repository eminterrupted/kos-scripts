@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local orientation to "pro-radOut".
local facingPart to ship:rootpart.

// Parse Params
if params:length > 0 
{
  set orientation to params[0].
  if params:length > 1 set facingPart to params[1].
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

until false
{
    set sVal to GetSteeringDir(orientation).
    DispOrbit().
}