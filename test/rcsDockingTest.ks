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

local dockingVec  to v(0, 0, 0).
local relVelocity to v(0, 0, 0).

local dockingPorts  to list().
local myPort        to "".
local targetPort    to "".

list dockingPorts   in dockingPorts.
set myPort          to dockingPorts[0].
myPort:controlFrom.

if target:dockingport:length > 0 
{
    set targetPort to target:dockingPorts[0].
}
else 
{
    print "Target has no docking port".
    print 1 / 0.
}

print " ".
print "Target selected: " + target.
print "Enable RCS to begin docking test".
print " ".
wait until rcs.

print "Cancelling relative velocity".
lock relVelocity to ship:velocity:orbit - targetPort:ship:velocity:orbit.
until relVelocity:mag < 0.1 
{
    translate(-(relVelocity)).
}
translate().

print "Aligning for docking".
lock steering to -(targetPort:portFacing:vector).

print "Docking".
lock dockingVec to targetPort:nodePosition - myPort:nodePosition.
until targetPort:state <> "Ready" 
{
    translate(dockingVec:normalized - relVelocity).
}
translate().
rcs off.

print "Docking complete!".

global function translate
{
    parameter vec is v(0, 0, 0).

    set vec to vec:normalized. 

    set ship:control:fore       to vDot(vec, ship:facing:forevector).
    set ship:control:starboard  to vDot(vec, ship:facing:starvector).
    set ship:control:top        to vDot(vec, ship:facing:topvector).
}