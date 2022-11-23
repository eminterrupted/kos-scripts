@lazyGlobal off.
clearScreen.

parameter params to list().

DispMain(ScriptPath()).

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

local tgt_ap    to body:atm:height * 1.5.
local tgt_hdg   to 90. // 90 degrees (due east) is most efficient trajectory
local tgt_pit   to 90. // Needs to be 90 degrees as default to make pointy end stay pointed up
local tgt_rll   to 0.

if params:length > 0
{
    set tgt_ap to params[0].
    if params:length > 1 set tgt_hdg to params[1].
    if params:length > 2 set tgt_pit to params[2].
    if params:length > 3 set tgt_rll to params[3].
}

local gravTurnAlt to body:atm:height * 0.765.
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

local tgtLex to lexicon("tgt_ap", tgt_ap, "tgt_hdg", tgt_hdg, "tgt_pit", tgt_pit, "tgt_rll", tgt_rll).
local i to 0.
// If we've passed in overrides for defaults, set them here
for tgt in tgtLex:values
{
    print "tgt: {0} ({1})":format(tgt, tgt:typename).
    Breakpoint().
    if tgt:isType("string")
    {
        if tgtLex:keys[i] = "tgt_hdg" 
        {
            set tgt_hdg to tgt:toNumber(90).
            print "tgt_hdg: {0} ({1})":format(tgt, tgt:typename) at (2, 46).
        }
        else if tgtLex:keys[i] = "tgt_pit" 
        {
            set tgt_pit to tgt:toNumber(90).
            print "tgt_pit: {0} ({1})":format(tgt_pit, tgt_pit:typename) at (2, 47).
        }
        else if tgtLex:keys[i] = "tgt_rll" 
        {
            set tgt_rll to tgt:toNumber(0).
            print "tgt_rll: {0} ({1})":format(tgt_rll, tgt_rll:typename) at (2, 48).
        }
        else if tgtLex:keys[i] = "tgt_ap" 
        {
            if tgt:matchesPattern("\d+km") set tgt_ap to tgt_ap:replace("km", "000"):toNumber(body:atm:height * 1.25).
            print "tgt_ap: {0} ({1})":format(tgt_ap, tgt_ap:typename) at (2, 49).
        }
    }
    set i to i + 1.
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
    print "tgt_ap: {0} ({1})":format(tgt_ap, tgt_ap:typename) at (2, 45).
    DispLaunchTelemetry(list(tgt_ap)).
    // OutInfo("Stage: {0}":format(Stage:Number), 0).
    // OutInfo("tgt_pit: {0}":format(round(tgt_pit, 2)), 1).
    wait 0.01.
}

until stage:number = g_stopStage
{
    set tgt_pit to GetAscentAngle(gravTurnAlt).
    set sVal to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    // OutInfo("Stage: {0}":format(Stage:Number), 0).
    // OutInfo("tgt_pit: {0}":format(round(tgt_pit, 2)), 1).
    wait 0.01.
}

set g_activeEngines to ActiveEngines().
until g_activeEngines:Thrust < 0.01 or ship:apoapsis >= tgt_ap
{
    set tgt_pit to GetAscentAngle(gravTurnAlt).
    set sVal to heading(tgt_hdg, tgt_pit, tgt_rll).
    // if ship:altitude > lastAlt set maxAlt to ship:altitude.
    DispLaunchTelemetry(list(tgt_ap)).
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
    DispLaunchTelemetry(list(tgt_ap)).
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
        DispLaunchTelemetry(list(tgt_ap)).
        wait 0.01.
    }
}
OutMsg("Script complete!").