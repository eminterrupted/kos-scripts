@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").
RunOncePath("0:/lib/launch").

DispMain(ScriptPath():name).

// Declare Variables
local runmode to 0. // Used to identify which loop to use
local program to 0. // Used to control flow within a loop
                    // Example: Loop 1 may be running the pre-launch check,
                    //          and program would identify the current step


// Load the loopDelegates

// Auto-Staging delegate
InitStagingDelegate@.

// Abort Delegate. This triggers if the runmode is ever negative, 
// and takes the program index as the parameter to determine which abort mode
// to use
set g_LoopDelegates["Abort"] to LaunchAbort@.

// Now the program delegates
// Even numbers = success or in progress
// Odd numbers are abort or error scenarios
// Program numbers are incremented by g_ErrorLevel that is set by the function
// Possible g_ErrorLevel values: 
//      0: Continue looping on this delegate
//      1: Error or abort scenario
//      2: Continue to next delegate 

local programDelegates to lexicon().
set programDelegates[0] to { return LaunchPreChecks(g_RunMode).      }.
set programDelegates[2] to { return LaunchCountdown(g_RunMode).         }.
set programDelegates[4] to { return LaunchVerticalAscent(g_RunMode). }. // runmode 0: Clear Tower. runmode 2: Roll Program. Runmode 4: Continue
set programDelegates[6] to { return LaunchDownRangeTurn(g_RunMode).  }.
set programDelegates[8] to { return LaunchCoastToSpace(g_RunMode).   }.
set g_LoopDelegates["Program"] to programDelegates.



// Parse Params
if params:length > 0 
{
  set foo to params[0].
}

until program = -1
{
    set g_RunMode to g_RunMode + g_loopDelegates["Program"][program]:Call(g_Runmode).
    
    if runmode < 0 
    {
        g_LoopDelegates["Abort"]:Call(program).
    }
    else
    {
        set program to program + g_ErrorLevel.
    }

    if g_LoopDelegates:HasKey("Staging")
    {
        if g_LoopDelegates["Staging"]:Check
        {
            g_LoopDelegates["Staging"]:Action:Call().
        }
    }

    from { local i to 0.} until i = g_LoopDelegates["Display"]:Keys:Length step { set i to i + 1.} do
    {
        g_LoopDelegates["Display"]:Values[i]:Call(g_LoopDelegates["Display"]:Keys[i]).
    }

    ExecGLoopEvents().

}


local function LaunchPreChecks
{
    parameter _runmode to g_RunMode.

    local returnCode to 0.

    OutMsg("Press ENTER to LAUNCH; INSERT to recalc CORE:TAG").
    until g_TermChar = Terminal:Input:Enter
    {
        GetTermChar().
        if g_TermChar = Terminal:Input:InsertCursor
        {
            OutInfo("Recalculating CORE:TAG").
            set g_MissionTag to ParseCoreTag(core:tag).
            wait 1.
            OutInfo("New Core Mission: [{0}]":Format(g_MissionTag:Mission)).
            wait 2.
        }
    }
    
    ClearScreen.
    // DispTermGrid().
    DispMain(ScriptPath()).
    OutMsg("Launch initiated!").
    lock Throttle to 1.
    wait 0.25.
    LaunchCountdown().
    OutInfo().
    OutInfo("",1).

    set g_ActiveEngines to GetEnginesForStage(Stage:Number).
    set g_NextEngines   to GetNextEngines().


    // local AutoStageResult to ArmAutoStaging().
    ArmAutoStaging().

    // Arm hot staging if present
    set g_HotStagingArmed to ArmHotStaging().

    // if AutoStageResult = 1
    // {
    //     set stagingDelegateCheck  to g_LoopDelegates:Staging["Check"].
    //     set stagingDelegateAction to g_LoopDelegates:Staging["Action"].
    // }

    set g_BoostersArmed to ArmBoosterStaging().

    set s_Val to Ship:Facing.
    lock steering to s_Val.

    OutMsg().
    OutInfo().
    OutInfo("", 1).

    OutMsg("Liftoff! ").
    wait 1.

    return returnCode.
}

local function LaunchAbort
{
    local returnCode to 0.

    return returnCode.
}

local function LaunchVerticalAscent
{
    local returnCode to 0.

    return returnCode.
}

local function LaunchDownRangeTurn
{
    local returnCode to 0.

    return returnCode.
}

local function LaunchCoastToSpace
{
    local returnCode to 0.

    return returnCode.
}