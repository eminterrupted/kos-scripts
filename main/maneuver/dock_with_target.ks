@lazyGlobal off. 

sas off.
rcs off.
clearScreen.

translate().
clearVecDraws().


wait 1.

local capturePort   to "".
local dockingPorts  to list().
local probePort     to "".
local safetyDist    to 75.
local targetPort    to "".

if not hasTarget {
    print "Select a target".
    until hasTarget
    {
        wait 0.01.
    }
}

list dockingPorts   in dockingPorts.
set probePort          to dockingPorts[0].
probePort:controlFrom.

if target:typeName = "Vessel" 
{
    if target:dockingports:length > 1 
    {
        for dp in target:dockingPorts 
        {
            if dp:tag = "portA" set capturePort to dp.
        }
    }
    else if target:dockingPorts:length > 0 
    {
        set capturePort to target:dockingPorts[0].
    }
    else
    {
        print "Target has no docking port".
        print 1 / 0.
    }
}
else if target:typeName <> "dockingPort" 
{
    print "Not a valid target type".
    print 1 / 0.
}

print " ".
print "Target selected: " + target.
print "Enable RCS to begin docking test".
print " ".
wait until rcs.

print "Cancelling relative velocity".
kill_rel_vel(capturePort, probePort).

print "Ensuring sufficient safety range (" + safetyDist + ")".
clear_docking_port(capturePort, probePort, safetyDist, 1).

print "Cancelling relative velocity".
kill_rel_vel(capturePort, probePort).

if vang(-(probePort:facing:vector), capturePort:facing:vector) <= -180 or vang(-(probePort:facing:vector), capturePort:facing:vector) >= -180
{
    print "Positioning at port side".
    position_port_side(capturePort, probePort, safetyDist, 1).
}

print "Cancelling relative velocity".
kill_rel_vel(capturePort, probePort).

print "Making " + safetyDist + "m approach".
approach_docking_port(capturePort, probePort, safetyDist, 2.5).

print "Making 50m approach".
approach_docking_port(capturePort, probePort, 50, 1.5).

print "Making 25m approach".
approach_docking_port(capturePort, probePort, 25, 1).

print "Making 10m approach".
approach_docking_port(capturePort, probePort, 10, 1).

print "Making final approach".
approach_docking_port(capturePort, probePort, 0, 0.5).

translate().
rcs off.

print "Docking complete!".









global function translate
{
    parameter vec is v(0, 0, 0).

    if vec:mag > 1 set vec to vec:normalized. 
    
    set ship:control:fore       to vDot(vec, ship:facing:forevector).
    set ship:control:starboard  to vDot(vec, ship:facing:starvector).
    set ship:control:top        to vDot(vec, ship:facing:topvector).
}

global function kill_rel_vel 
{
    parameter tgtPort,
              ctrlPort.
    
    ctrlPort:controlFrom().

    lock relVel to ctrlPort:ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to ship:facing.
    until relVel:mag < 0.1 
    {
        translate(-(relVel)).
    }
    translate().
}

global function approach_docking_port
{
    parameter tgtPort,
              ctrlPort,
              dist,
              spd.

    ctrlPort:controlFrom().

    lock distOffset to tgtPort:portFacing:vector * dist.
    lock approachVec to tgtPort:nodePosition - ctrlPort:nodePosition + distOffset.
    lock relVel to ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to -(tgtPort:portFacing:vector).

    until ctrlPort:state <> "ready" 
    {
        translate((approachVec:normalized * spd) - relVel).
        local distVec to (tgtPort:nodePosition - ctrlPort:nodePosition).
        if vang(ctrlPort:portFacing:vector, distVec) < 2 and abs(dist - distVec:mag) < 0.1 
        {
            break.
        }
        wait 0.01.
    }
}

global function clear_docking_port
{
    parameter tgtPort,
              ctrlPort,
              dist,
              spd.

    ctrlPort:controlFrom().

    lock relPosition to ship:position - tgtPort:ship:position.
    lock departVec to (relPosition:normalized * dist) - relPosition.
    lock relVel to ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to -(tgtPort:portFacing:vector).

    until false 
    {
        translate((departVec:normalized * spd) - relVel).
        if departVec:mag < 0.1 
        {
            break.
        }
        wait 0.01.
    }
}

global function position_port_side
{
    parameter tgtPort, 
              ctrlPort, 
              dist, 
              spd. 

    ctrlPort:controlFrom().

    lock sideDir to tgtPort:ship:facing:starVector.
    if abs(sideDir * tgtPort:portFacing:vector) = 1 
    {
        lock sideDir to targetPort:ship:facing:topVector.
    }

    lock distOffset to sideDir * dist.
    lock approachVec to tgtPort:nodePosition - ctrlPort:nodePosition + distOffset. 
    lock relVel to ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to -(tgtPort:portFacing:vector).

    until false 
    {
        translate((approachVec:normalized * spd) - relVel).
        if approachVec:mag < 0.1
        {
            break.
        }
        wait 0.01.
    }
}