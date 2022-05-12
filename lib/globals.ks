// #include "0:/boot/_bl"

// Boot Loader globals
if not (defined lp) global lp to list().
if not (defined plan)   global plan to "".
if not (defined branch) global branch to "".
if not (defined partC)  global partC to "".
if not (defined missionName) global missionName to Ship:Name.

global g_abortGroup to lexicon().
global g_abortSystemArmed to false.
global g_boosterSystemArmed to false.
global g_cacheFile to "".
global g_MECO to 0.
global g_orientation to "pro-sun".
global g_termChar to "".
global g_stagingTime to 0.