// #include "0:/boot/_bl"

// Params for globals

// Flow Control
global errLvl to 0.
global g_stack to lex().
global g_stackHoles to list().
global g_stackIdx to 0.

// Math helpers
global g_safeMin to 0.0000000000000001.

// Parse the tags
local tagSplit to core:tag:split("|").
global g_tags is list().

for t0 in tagSplit[0]:split(":") 
{
    g_tags:add(t0).
}
//if tagSplit:length > 1 g_tags:add(tagSplit[1]).

// Boot Loader globals
if not (defined mpArc)  global mpArc to "".
if not (defined mpLoc)  global mpLoc to "".
if not (defined lp)     global lp to list().
if not (defined plan)   global plan to choose g_tags[0] if g_tags:length > 0 else "".
if not (defined branch) global branch to choose g_tags[1] if g_tags:length > 1 else "".
if not (defined g_stopStage) global g_stopStage to choose tagSplit[1] if tagSplit:length > 1 else 0.
if not (defined partC)  global partC to "".
if not (defined missionName) global missionName to Ship:Name.

global g_col to 0. // Display horizontal positioning key
global g_line to 10. // Display vertical positioning key
global g_prn to "". // A single-line buffer for writing text to terminal

global g_cpus to ship:modulesNamed("kOSProcessor").

global g_cacheFile to "".
global g_MECO to 0.
global g_termChar to "".
global g_engBurnout to false.

// Control
global sVal to ship:facing.
global tVal to 0.

global g_orientation to "pro-sun".
global g_abort to abort.
global g_abortGroup to lexicon().
global g_abortSystemArmed to false.
global g_boosterSystemArmed to false.
global g_staged to false.
global g_stagingTime to 0.

global g_alarmTimer to 0.