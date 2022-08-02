parameter params is list().

local srcElement is ship:elements[0].
local tgtElement is ship:elements[0].
local srcRes to "".
local finalPct to 1.


// Parse Params
if params:length > 0 
{
  set srcElement to params[0].
  if params:length > 1 set tgtElement to params[1].
  if params:length > 2 set srcRes to params[2].
  if params:length > 3 set finalPct to params[3].
}

runPath("0:/main/util/transferResource", list(srcElement, tgtElement, srcRes, finalPct)).