@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/kslib/lib_loader").
runOncePath("0:/kslib/lib_l_az_calc").

runOncePath("0:/lib/control").
runOncePath("0:/lib/module").
runOncePath("0:/lib/term").
runOncePath("0:/lib/engine").
runOncePath("0:/lib/vlc").

// Setup terminal display
init_term(true, true, true).

// Declare Variables
local compit to compass_and_pitch_for(Ship, Ship:Facing).
local launchAng to compit[1].
local launchHdg to compit[0].
local launchTS to 5.
local stageLimit to 0.
local transAltSpd to 32.5.
local transAltWindow  to 2781.

local transEndPitch is 79.25.

// Parse Params
if _params:length > 0 
{
  set stageLimit to _params[0].
  if _params:Length > 1 set launchHdg  to _params[1].
  if _params:Length > 2 set launchAng  to _params[2].
  if _params:Length > 3 set transAltWindow  to _params[3].
  if _params:Length > 4 set transAltSpd to _params[4].
}

// Setup initial control environment
out_msg("Initial Control Setup").
local steerDel to { return Ship:Facing.}.
set sVal to steerDel:Call().
set tVal to 0.
set rVal to 0.

// Setup countdown
out_msg("Setting up countdown").

local cdSeqObj to init_countdown().
local padStage to cdSeqObj:PadStage.

// Confirm launch go
out_msg("Confirming countdown go").
out_debug("stageLimit: {0}":Format(stageLimit)).
// Hold
terminal_countdown_hold(cdSeqObj).

// Execute countdown
set cdSeqObj to cdSeqObj:SetLaunchTS:Call(cdSeqObj, Time:Seconds).
set launchTS to cdSeqObj:LaunchTS.

// Transition to internal guidance
lock steering to sVal.
lock throttle to tVal.

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
    set tVal to 0.
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
set steerDel to { parameter _pit. return Heading(launchHdg, _pit, rVal).}.

local curPitch to pitch_for(Ship, Ship:Facing).
set transEndPitch to Round(min(curPitch, max(transEndPitch, pitch_for(Ship, Ship:srfPrograde) - 15)), 2).
set altThresh to launch_pitch_program(transEndPitch, transAltWindow, altThresh, curPitch, 0.625, steerDel@).
//set altThresh to launch_pitch_program(transEndPitch, transAltWindow, altThresh, steerDel@).

// Lock to SrfPrograde for gravity turn until we reach 50km or 1750m/s
set altThresh to launch_gravity_turn(steerDel, "srf", 12.5, 50000, 1750).

// Transition pitch to orbit prograde
set curPitch to pitch_for(Ship, Ship:Facing).
local obtProPit to pitch_for(Ship, Ship:Prograde).
set altThresh to launch_pitch_program(obtProPit, 2000 * Round(curPitch - obtProPit), altThresh, curPitch, 0.425, steerDel@).
rcs on.

// Lock to ObtPrograde for gravity turn, max pitch to +3.25 degrees
set altThresh to launch_gravity_turn(steerDel, "obt", 3.25).

out_msg("downrangerLaunch complete").
out_msg("", 1).
out_info("").
out_info("", 1).
out_info("", 2).
