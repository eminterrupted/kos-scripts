@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/lib/kslib/lib_loader").
runOncePath("0:/lib/kslib/lib_l_az_calc").
runOncePath("0:/lib/control").
runOncePath("0:/lib/module").
runOncePath("0:/lib/term").
runOncePath("0:/lib/engine").
runOncePath("0:/lib/vlc").

// Setup terminal display
init_term(true, true, true).

// Declare Variables
local compit to compass_and_pitch_for(Ship, Ship:Facing:ForeVector).

local launchAng to compit[1].
local launchHdg to compit[0].
local stageLimit to StageLimit.

// Parse Cmd Params
if _params:length > 0 
{
  set launchHdg to _params[0].
  if _params:Length > 1 set launchAng to _params[1].
  if _params:Length > 2 set stageLimit to _params[2].
}

// Setup initial control environment
out_msg("Initial Control Setup").
local steerDel to { parameter _tgtHdg is launchHdg, _tgtRoll is rVal, _tgtPit is launchAng. return Heading(_tgtHdg, _tgtPit, _tgtRoll). }.
set steerDel to steerDel@:Bind(launchHdg, rVal).
set SVal to Ship:Facing.
set TVal to 0.

// Setup countdown
out_msg("Setting up countdown").

local cdSeqObj to init_countdown().
local padStage to cdSeqObj:PadStage.

// Confirm launch go
out_msg("Confirming countdown go").

// Hold
terminal_countdown_hold(cdSeqObj).

// Execute countdown
set cdSeqObj to cdSeqObj:SetLaunchTS:Call(cdSeqObj, Time:Seconds).
local launchTS to cdSeqObj:LaunchTS.

// Transition to internal guidance
lock steering to SVal.
lock throttle to TVal.

// Term count reached, evaluate the launch thrust state to ensure we have enough for liftoff
local termCountComplete to exec_term_countdown(cdSeqObj).

// Term count reached, evaluate the launch thrust state to ensure we have enough for liftoff
if termCountComplete
{
    local goFlag to false.
    until goFlag 
    {
        out_msg("Mission Clock   : T {0}":Format(Round(Time:Seconds - launchTS, 2)), 1).
        set goFlag to eval_launch_commit_thrust().
        wait 0.01.
    }
}
else
{
    set TVal to 0.
    out_msg("ERR: Idk how we ended up here. Weird").
    out_msg(" ", 1).
    out_info(" ").
    out_info(" ", 1).
    wait 9.
    print 1 / 0.
}

// Release clamps and go
launch_commit_go(padStage).

local altThresh to 0.

// Hold steady until we clear the tower
set altThresh to launch_clear_tower().
// Initial pitch over
local curPitch to pitch_for(Ship, Ship:Facing).
local pitDeltaMax to 0.625.
set altThresh to launch_pitch_program(stageLimit, steerDel@, launchAng, 1250, pitDeltaMax, altThresh, curPitch).

set SVal to Ship:Facing.

local doneFlag to false.
local tchar to "".
until doneFlag
{   
    set tchar to get_term_char().
    set doneFlag to tchar = terminal:Input:Enter.
    set tchar to "".
    
    out_msg("Mission Clock   : T {0}":Format(Round(MissionTime, 2)), 1).
    if Stage:Number > StageLimit
    {
        // local activeEngines to get_active_engines(Ship, "nosep").

        if Ship:AvailableThrust < 0.01 
        {
            wait until Stage:Ready.
            stage.
        }
        out_msg("Powered Ascent").
        local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
        out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        out_info("", 2).
    }
    else
    {
        out_msg("Passive Coast").
        out_info("", 1).
        out_info("", 2).
    }
    out_info("Alt: {0} | VSpd: {1}":Format(Round(Ship:Altitude), Round(Ship:VerticalSpeed, 1))).
}

clearScreen.
print "donezo".