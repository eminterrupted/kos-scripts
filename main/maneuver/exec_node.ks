@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").

disp_main(scriptPath()).
disp_msg("Executing maneuver node").
// Execute
mnv_exec_node_burn(nextNode).