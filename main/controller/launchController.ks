@lazyGlobal off.
clearScreen.

//#include "0:/boot/bootLoader.ks"

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").

disp_main(scriptPath()).

local circPath      to choose path("0:/main/launch/circ_burn_node") if career():canMakeNodes else path("0:/main/launch/circ_burn_simple").
local launchCache   to dataDisk + "launchPlan.json".
local launchPlan    to readJson(launchCache).
local launchQueue   to launchPlan:queue.

ag9 off.
until launchQueue:length = 0
{
    if ship:status = "PRELAUNCH" or ship:status = "LANDED"
    {
        if ship:status = "PRELAUNCH" 
        {
            disp_msg("Enabling external power").
            launch_pad_gen(true).
            wait 1.
        }

        disp_launch_plan(launchPlan).
        local ts to time:seconds + 5.
        ag10 off.
        until time:seconds > ts or ag10
        {
            disp_msg("Reviewing plan, press 0 to skip").
            if ag10 break.
            if terminal:input:hasChar
            {
                if terminal:input:getChar() = "0" break.
            }
        }
        ag10 off.

        if launchPlan:waitForLAN or launchPlan:tgtLAN <> -1
        {
            runPath("0:/util/launchIntoLAN", launchPlan:tgtLAN, launchPlan:tgtInc).
        }
        else
        {
            ag10 off.
            until ag10
            {
                disp_tee("Activate AG10 to initiate immediate launch").
                wait 0.01.
            }
            ag10 off.
        }

        download(circPath).
        runPath("0:/main/launch/" + launchQueue:pop(), launchPlan).
        writeJson(launchPlan, launchCache).
    }
    else 
    {
        local curScript to choose path("local:/" + launchQueue:pop()) if exists(path("local:/" + launchQueue:peek())) else path("0:/main/launch/" + launchQueue:pop()).
        runPath(curScript, launchPlan).
        writeJson(launchPlan, launchCache).
    }
}
ag9 off.
ag9 on.
deletePath(launchCache).
ag9 off.