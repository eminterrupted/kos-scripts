@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").
RunOncePath("0:/lib/launch").

set g_MainProcess to ScriptPath().
DispMain().

// Declare Variables
local runmode to 0. // Used to identify which loop to use
local program to 0. // Used to control flow within a loop
                    // Example: Loop 1 may be running the pre-launch check,
                    //          and program would identify the current step


// Parse Params
if params:length > 0 
{
  set foo to params[0].
}

until program = -1
{
    

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