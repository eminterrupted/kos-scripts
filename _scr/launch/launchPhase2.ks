@lazyGlobal off.
clearScreen.

parameter params to list().

DispMain(ScriptPath()).

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

local tgt_ap    to body:atm:height * 6.
local tgt_hdg   to 90.
local tgt_pit   to 90.
local tgt_rll   to 0.

if params:length > 0
{
    set tgt_ap to params[0].
    if params:length > 1 set tgt_hdg to params[1]:toNumber(0).
    if params:length > 2 set tgt_pit to params[2]:toNumber(0).
    if params:length > 3 set tgt_rll to params[3]:toNumber(0).
}

local f_spinStab to false.
local f_hotStage to false.

local doneFlag to false.

// Script flags can be added to the global g_scriptFlags object
local f_spinStabID to "f_spinStab".
local f_spinStab   to false.
set g_scriptFlagDelegates[f_spinStabID] to { parameter val. set f_spinStab to val.}.
set g_scriptFlags[f_spinStabID] to f_spinStab.

local f_hotStageID    to "f_hotStage".
local f_hotStage        to false.
set g_scriptFlagDelegates[f_hotStageID] to { parameter val. set f_hotStage to val.}.
set g_scriptFlags[f_hotStageID] to f_hotStage.

// Validate the tgt_ap value
if tgt_ap:isType("string")
{
    if tgt_ap:contains("km") 
    {
        set tgt_ap to tgt_ap:replace("km", "000"):toNumber(0).
    }
    else
    {
        set tgt_ap to tgt_ap:toNumber(0).
    }
}

// Check the vessel for decouplers that are tagged for spin stabilization or hot staging
for dc in ship:decouplers
{
    if dc:tag:matchesPattern(".*spinStab.*")
    {
        set f_spinStab to SetScriptFlag(f_spinStabID, true).
        OutInfo("Spin Stabilized Stage").
    }
    if dc:tag:matchesPattern(".*hotStage.*")
    {
        set f_hotStage to SetScriptFlag(f_hotStageID, true).
        OutInfo("Hot Staging").
    }
}

OutMsg("Press Enter to begin launch countdown").
until false
{
    if terminal:input:hasChar
    {
        set g_tChar to terminal:input:getchar.
    }
    if g_tChar = terminal:input:enter break.
}
lock throttle to tVal.
lock steering to sVal.

OutMsg("Commencing launch countdown").
LaunchCountdown().
set tVal to 1.
OutMsg("Liftoff!").

ArmAutoStaging().

until ship:altitude > g_la_turnAltStart
{
    DispSoundingTelemetry(list(tgt_ap)).
    // OutInfo("Stage: {0}":format(Stage:Number), 0).
    // OutInfo("tgt_pit: {0}":format(round(tgt_pit, 2)), 1).
    wait 0.01.
}

until stage:number = g_stopStage
{
    set tgt_pit to GetAscentAngle(tgt_ap).
    set sVal to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispSoundingTelemetry(list(tgt_ap)).
    // OutInfo("Stage: {0}":format(Stage:Number), 0).
    // OutInfo("tgt_pit: {0}":format(round(tgt_pit, 2)), 1).
    wait 0.01.
}

set g_activeEngines to ActiveEngines().
until g_activeEngines:Thrust < 0.01 or ship:apoapsis >= tgt_ap
{
    set tgt_pit to GetAscentAngle(tgt_ap).
    set sVal to heading(tgt_hdg, tgt_pit, tgt_rll).
    // if ship:altitude > lastAlt set maxAlt to ship:altitude.
    DispSoundingTelemetry(list(tgt_ap)).
    // OutInfo("SECO BURN", 0).
    // OutInfo("tgt_pit: {0}":format(round(tgt_pit, 2)), 1).
    set g_activeEngines to ActiveEngines().
    wait 0.01.
}
OutMsg("Engine Cutoff").
// OutInfo().

local ts to time:seconds + eta:apoapsis.
until time:seconds >= ts
{
    set ts to time:seconds + eta:apoapsis.
    set sVal to lookDirUp(ship:prograde:vector, -body:position).
    // if ship:altitude > lastAlt set maxAlt to ship:altitude.
    DispSoundingTelemetry(list(tgt_ap)).
    wait 0.01.
}
OutMsg("Apoapsis reached").
unlock steering.

until doneFlag
{
    if alt:radar < 2 
    {
        set doneFlag to true.
    }
    else
    {
        DispSoundingTelemetry(list(tgt_ap)).
        wait 0.01.
    }
}
OutMsg("Script complete!").