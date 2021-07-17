@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").

if sci_arm_hammer()
{
    disp_msg("Performing Seismic Hammer Experiment").
    local ts to time:seconds + 60.
    until time:seconds >= ts
    {
        disp_info("Time until experiment completion: " + round(ts - time:seconds, 2) + "s").
    }
    sci_deploy_hammer().
}