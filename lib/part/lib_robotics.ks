@lazyGlobal off.

local robMod is "ModuleRoboticServoHinge".

global function toggle_hinge {
    parameter p,
              wTime is 2.

    local m to p:getModule(robMod).
    
    if m:hasAction("toggle hinge") m:doAction("toggle hinge", true).
    wait wTime.
}