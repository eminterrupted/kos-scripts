@lazyGlobal off.

runOncePath("0:/lib/lib_util").

local robMod is "ModuleRoboticServoHinge".

global function toggle_hinge 
{
    parameter p,
              wTime is 2.

    do_action(p:getModule(robMod), "toggle hinge").
    wait wTime.
}