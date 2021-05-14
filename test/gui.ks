@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_gui").
runOncePath("0:/lib/lib_launch").

local launchPlan    to "".
local missionPlan   to "".
local tgtAp     to 175000.
local tgtPe     to 175000.
local tgtInc    to 0.
local tgtRoll   to 0.
local lazObj    to list().   
local doReturn  to true.

// General pattern:
// -- Current queue on left, selector in middle, params on right
// -- Build lists, then read those into queues
// -- Script button in selector - add. Script button in queue - remove
// -- To identify params, build a lex that contains script names to lex of params
// -- Store param lex somewhere (archive until script is downloaded), then when running the script, use it as the parameter

// Tab 0 - Mission profile
// Suborbital
// Orbital
// Mun transfer

// Tab 1 - Launch queue
// Enumerate launch scripts
// Select a launch script
// -- Default to multiStage.ks
// -- Search archive lex containing all scripts and params for this script
// Define launch parameters
// -- launchAp
// -- launchPe
// -- launchInc
// -- launchArgPe
// -- launchRoll
// If not suborbital, select circ script

// Tab 2 - Mission queue
// Enumerate mission scripts
// Select first mission script
// -- Search archive lex containing all scripts and params for this script
// -- Define script 1 params
// Select next mission script
// ...

// Tab 3 - Return queue
// Toggle for return or not
// If return, enumerate return scripts
// -- Select first return script (i.e., ksc_reentry, return from mun, deorbit, etc)
// ---- Search archive lex containing all scripts and params for this script
// ---- Fill out necessary params
// -- Select second script (if necessary)
// If not return, set script to suborbital reentry.
