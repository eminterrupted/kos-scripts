@lazyGlobal off.
clearScreen.

parameter plan.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local tgtPe to plan[0].
local tgtAp to plan[1].
local tgtInc to plan[2].
local tgtLAN to plan[3].
local tgtArgPe to plan[4].
