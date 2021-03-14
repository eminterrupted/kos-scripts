@lazyGlobal off.
clearScreen.

sas off.
rcs off.

translate().
clearVecDraws().

print "Select a target".
until hasTarget
{
    wait 0.01.
}
wait 1.

local relVelocity to 0.

print "Target selected: " + target.
print "Enable RCS to begin docking test".
print " ".
wait until rcs.

print "Cancelling relative velocity".
lock relVelocity to ship:velocity:orbit - target:velocity:orbit.
until relVelocity:mag < 0.1 
{
    translate(-(relVelocity)).
}
translate().
rcs off.

print "Rendezvous complete!".

global function translate
{
    parameter vec is v(0, 0, 0).

    set vec to vec:normalized. 

    set ship:control:fore       to vDot(vec, ship:facing:forevector).
    set ship:control:starboard  to vDot(vec, ship:facing:starvector).
    set ship:control:top        to vDot(vec, ship:facing:topvector).
}