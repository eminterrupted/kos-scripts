@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/lib/deploader").
runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/module").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/engine").

// Setup terminal display
InitTerm(true, true, true).

// Declare Variables
local curVAng  to 90.
local lastVAng to 90.

local curDirComponents to compass_and_pitch_for(Ship, Ship:Facing).
local launchHdg to curDirComponents[0].
local launchAng to curDirComponents[1].

local modeSwVSpd to 32.5.
local prgdSwAlt  to 1250.

// Parse Params
if _params:length > 0 
{
  set launchHdg to _params[0].
  if _params:Length > 1 set launchAng  to _params[1].
  if _params:Length > 2 set prgdSwAlt  to _params[2].
  if _params:Length > 3 set modeSwVSpd to _params[3].
}

// Setup initial control environment
// Delegate to converge on Orbital Prograde by following SrfPrograde until VAng is less than 1 degree
local steerDelPhases to list(
    { return Heading(launchHdg, curDirComponents[1]).},
    { return Heading(launchHdg, launchAng).},
    { set lastVAng to curVAng. set curVAng to Abs(pitch_for(Ship, Ship:SrfPrograde) - pitch_for(Ship, Ship:Prograde)). if curVAng <= 1 { return Ship:Prograde.} else if curVAng <= lastVAng { return Ship:SrfPrograde.} else { return Ship:Prograde.}}
).

local steerDel to steerDelPhases[0].

local sVal to steerDel:Call().
local tVal to 0.

// #TODO: Setup countdown

// init_countdown :: ([_cdObj<lexicon>])
global function init_countdown
{
    parameter _cdObj is lex("cdTime", 5).

    // Get the pad stage.
    

    // -- Get spool time for engines in launch stage
    local stgEngs to GetBurnStageEngines(Ship, padStage + 1, true).
    local maxSpool to 0.
    from { local i to stgEngs:Length - 1.} until i < 0 step { set i to i - 1.} do
    {
        local eng to stgEngs[i].
        local m to eng:GetModule("ModuleEnginesRF").
        local fldStr to "effective spool-up time".

        if not m:HasField(fldStr)
        {
            stgEngs:Remove(i).
        }
        else
        {
            set maxSpool to max(maxSpool, m:GetField(fldStr)).
        }
    }

    return lex().
}

// Confirm launch go
OutMsg("Press any key to launch").
Breakpoint(" ").

// #TODO: Execute countdown
local spoolTS  to Time:Seconds + cdTimer.
local launchTS to spoolTS + Round(maxSpool).

local ignSeqStart to false.

lock steering to sVal.

OutMsg("Launch Countdown").
until Time:Seconds > launchTS
{
    if ignSeqStart
    {
        OutMsg("Launch Countdown: T-{0}":Format(Round(launchTS - Time:Seconds, 2))).
        local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
        OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
    }
    else
    {
        if Time:Seconds >= spoolTS
        {
            OutInfo("Ignition sequence start").
            set tVal to 1.
            lock throttle to tVal.
            set ignSeqStart to MainEnginesIgnition(padStage).
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }
        else
        {
            OutInfo("Ignition sequence armed").
            OutMsg("Launch Countdown: T-{0}":Format(Round(launchTS - Time:Seconds, 2))).
        }
    }
}

local goFlag to false.
until goFlag
{
    set goFlag to LaunchCommitEval(launchTS).
    wait 0.01.
}

LaunchCommit(padStage).

until Alt:Radar >= __vlcTowerHeight
{

}

until Ship:Altitude >= prgdSwAlt and Ship:VerticalSpeed >= modeSpeed 
{
    OutMsg("Mission Clock   : T {0}":Format(Round(MissionTime, 2))).
    if Stage:Number > 0
    {
        local activeEngines to GetActiveEngines(Ship, "nosep").

        if Ship:AvailableThrust < 0.01 
        {
            wait until Stage:Ready.
            stage.
        }
        OutInfo("Powered Ascent").
        local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
        OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
    }
    else
    {
        if Ship:AvailableThrust < 0.01 
        {
            OutInfo("Powered Ascent").
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }
        else
        {
            OutInfo("Passive Coast").
            OutInfo("",1).
        }
    }
}

set curVAng to VAng(Ship:SrfPrograde:Vector, Ship:Prograde:Vector).

local doneFlag to false.
until doneFlag
{
    set sVal to steerDel:Call().
    OutMsg("Mission Clock   : T {0}":Format(Round(MissionTime, 2)), 1).
    if Stage:Number > 0
    {
        local activeEngines to GetActiveEngines(Ship, "nosep").

        if Ship:AvailableThrust < 0.01 
        {
            wait until Stage:Ready.
            stage.
        }
        OutInfo("Powered Ascent").
        local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
        OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
    }
    else
    {
        OutInfo("Passive Coast").
        OutInfo("",1).
    }
}


// Local functions

// Stages the clamps
global function LaunchCommit
{
    parameter _padStg is getPadStage:Call().

    until Stage:Number = _padStg
    {
        until stage:Ready
        {
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            OutMsg("Launch Commit").
            OutInfo("Releasing clamps").
            OutInfo("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }
        stage.
    }
    OutMsg("Liftoff").

    return true.
}

// #TODO: Ignite engines
local function MainEnginesIgnition
{
    parameter _padStg is getPadStage:Call().

    local ignComplete to false.

    from { local i to Stage:Number.} until i = _padStg + 1 step { set i to i - 1.} do
    {
        wait until stage:ready.
        stage.
    }
    set ignComplete to true.
    
    return ignComplete.
}

// #TODO: Evaluate launch conditions
local function LaunchCommitEval
{
    parameter _launchTS.

    local launchCommitGo to false.
    local minThrPct to 0.9825.

    if Time:Seconds > _launchTS
    {
        set launchCommitGo to choose (ship:thrust / ship:AvailableThrust) > minThrPct if ship:Thrust > 0 else false.
    }
    OutMsg("Mission Clock   : T {0}":Format(Round(Time:Seconds - launchTS, 2)), 1).
    local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust, 4) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
    OutInfo("Thrust: {0} [{1,5}%/{2,5}%]":Format(Round(Ship:Thrust, 2), thrPct, Round(minThrPct * 100, 2))).
    OutInfo("Launch Commit: {0} ":Format(launchCommitGo), 1).

    return launchCommitGo.
}

// #TODO: Liftoff


// #TODO: Vertical Ascent

// #TODO: Coast