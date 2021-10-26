@lazyGlobal off.
clearScreen.

parameter reentryAlt is 35000.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

// Variables
local tgtBody to body("Kerbin").
local sVal to ship:prograde.
local tVal to 0.

lock steering to sVal. 
lock throttle to tVal.

set target to tgtBody.

disp_msg("Running transfer_to_body routine").
runPath("0:/main/maneuver/transfer_to_body").
disp_msg("Running wait_for_soi_change routine").
runPath("0:/main/maneuver/wait_for_soi_change").

disp_msg("Adjusting reentry angle routine").
local courseCorrect to node(time:seconds + 600, 0, 0, 0).
set courseCorrect to mnv_opt_simple_node(courseCorrect, reentryAlt, "pe", tgtBody).
add courseCorrect.

mnv_exec_node_burn(courseCorrect).
disp_msg("Reentry maneuver complete!").
