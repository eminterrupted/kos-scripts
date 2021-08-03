@lazyGlobal off.

parameter tgtPe.

local ts to time:seconds + eta:apoapsis.

local sVal to heading(90, 0, 0).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

until time:seconds >= ts - 15
{
    set sVal to heading(90, 0, 0).
}

set tVal to 1.
until ship:periapsis >= tgtPe * 0.995
{
    set sVal to heading(90, 0, 0).
}
set tVal to 0.