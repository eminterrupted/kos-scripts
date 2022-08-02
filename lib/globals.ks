// #include "0:/boot/_bl"

// Params for globals

// Parse the tags
local tagSplit to core:tag:split("|").
global g_tags is list().

for t0 in tagSplit[0]:split(":") 
{
    g_tags:add(t0).
}
if tagSplit:length > 1 g_tags:add(tagSplit[1]).

// Boot Loader globals
if not (defined lp)     global lp to list().
if not (defined plan)   global plan to "".
if not (defined branch) global branch to "".
if not (defined g_stopStage) global g_stopStage to g_tags[g_tags:length - 1].
if not (defined partC)  global partC to "".
if not (defined missionName) global missionName to Ship:Name.

global g_col to 0. // Display horizontal positioning key
global g_line to 10. // Display vertical positioning key
global g_logPath to Path("0:/log/_ini.log").
global g_log to g_logPath.
global g_locLogPath to Path("1:/log/loc.log").
global g_locLog to g_locLogPath.
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
global g_abortGroup to lexicon().
global g_abortSystemArmed to false.
global g_boosterSystemArmed to false.
global g_staged to false.
global g_stagingTime to 0.