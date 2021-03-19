@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").

disp_main(scriptPath()).

local dvNeeded to nextNode:burnvector:mag.
local burnAt   to nextNode:time.
local burnDur to mnv_burn_dur(dvNeeded).
local halfDur to mnv_burn_dur(dvNeeded / 2).
local burnEta to burnAt - halfDur.
disp_info("Burn duration: " + round(burnDur)).

// Execute
lock steering to nextNode:burnvector.
mnv_exec_circ_burn(burnEta, burnAt, burnEta).