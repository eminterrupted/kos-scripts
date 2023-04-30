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
set programDelegates[0] to { parameter _rm. return LaunchPreChecks(_rm).      }.
set programDelegates[2] to { parameter _rm. return LaunchCountdown().         }.
set programDelegates[4] to { parameter _rm. return LaunchVerticalAscent(_rm). }. // runmode 0: Clear Tower. runmode 2: Roll Program. Runmode 4: Continue
set programDelegates[6] to { parameter _rm. return LaunchDownRangeTurn(_rm).  }.
set programDelegates[8] to { parameter _rm. return LaunchCoastToSpace(_rm).   }.
set g_LoopDelegates["Program"] to programDelegates.



// Parse Params
if params:length > 0 
{
  set foo to params[0].
}

until program = -1
{
    g_loopDelegates["Program"][program]:Call(Runmode).
    
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

}


local function LaunchAbort
{

}

local function LaunchPreChecks
{
    local returnCode to 0.

    

    return returnCode.
}
