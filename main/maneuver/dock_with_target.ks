@lazyGlobal off. 
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

sas off.
rcs off.

translate().
clearVecDraws().

wait 1.

local capturePort   to "".
local dockingPorts  to list().
local lightList     to list().
local rcsList       to list().
local safetyDist    to 50.
local elementName   to ship:name.
local targetPort    to "".

local probePort     to rdz_select_probe_port().

// Get RCS
for p in ship:parts 
{
    if p:hasModule("ModuleRCSFX") or p:hasModule("ModuleRCS")
    {
        rcsList:add(p). 
    }

    if p:tag = "dockingLight" 
    {
        lightList:add(p:getModule("ModuleLight")).
    }
}

probePort:controlFrom.

if probePort:hasModule("ModuleAnimateGeneric")
{
    local portAnimate to probePort:getModule("ModuleAnimateGeneric").
    util_do_event(portAnimate, "open shield").
}

for m in lightList 
{
    util_do_event(m, "lights on").
}

set capturePort to rdz_select_docking_target().

disp_msg("Enable RCS to begin docking or 0 to reconfirm target").

until false
{
    if rcs break.
    if ag10 
    {
        set capturePort to rdz_select_docking_target().
    }
    ag10 off.
    disp_info("Target selected: " + capturePort).
    disp_info2("Probe port: " + probePort).
    wait 0.01.
}

disp_msg("Docking procedure activated").
disp_info().
disp_info2().

disp_info("Cancelling relative velocity").
kill_rel_vel(capturePort, probePort).

disp_info("Ensuring sufficient safety range (" + safetyDist + ")").
clear_docking_port(capturePort, probePort, safetyDist, 2).

disp_info("Cancelling relative velocity").
kill_rel_vel(capturePort, probePort).

if vang(-(probePort:facing:vector):normalized, capturePort:facing:vector:normalized) >= 180
{
    disp_msg("Positioning at port side").
    disp_info("vang: " + round(vang(-(probePort:facing:vector):normalized, capturePort:facing:vector:normalized), 5)).
    position_port_side(capturePort, probePort, safetyDist, 1).
}

disp_msg("Docking procedure in progress").

disp_info("Cancelling relative velocity").
kill_rel_vel(capturePort, probePort).

disp_info("Making " + safetyDist + "m approach").
approach_docking_port(capturePort, probePort, safetyDist, 1).

disp_info("Making 35m approach").
approach_docking_port(capturePort, probePort, 35, 1).

disp_info("Making 30m approach").
approach_docking_port(capturePort, probePort, 30, 1).

disp_info("Making 25m approach").
approach_docking_port(capturePort, probePort, 25, 0.5).

disp_info("Making 20m approach").
approach_docking_port(capturePort, probePort, 20, 0.5).

disp_info("Making 15m approach").
approach_docking_port(capturePort, probePort, 15, 0.5).

disp_info("Making 10m approach").
approach_docking_port(capturePort, probePort, 10, 0.25).

disp_info("Making 5m approach").
approach_docking_port(capturePort, probePort, 5, 0.25).

disp_info("Making 2.5m approach").
approach_docking_port(capturePort, probePort, 2.5, 0.25).

disp_info("Making final approach").
approach_docking_port(capturePort, probePort, 0, 0.25).

translate().

disp_msg("Capture").
disp_info().

// Shutdown systems
rcs off.
set core:bootfilename to "".

for m in lightList
{
    util_do_event(m, "lights off").
}

local localElement to ship.
for e in ship:elements 
{
    if e:name = elementName 
    {
        set localElement to e.
    }
}

local elementSolar to list().

for p in localElement:parts
{
    if p:hasModule("ModuleResourceConverter")
    {
        ves_activate_fuel_cell(p, false).
    }

    if p:hasModule("ModuleDeployableSolarPanel")
    {
        elementSolar:add(p:getModule("ModuleDeployableSolarPanel")).
    }
}

ves_activate_solar(elementSolar).

disp_msg("Hard dock complete!").

//TO DO - prevent script from running until undocked.

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
    rcs_toggle_full_thrust(rcsList).

    lock relVel to ctrlPort:ship:velocity:orbit - tgtPort:ship:velocity:orbit.
    lock steering to ship:facing.
    until relVel:mag < 0.15 
    {
        translate(-(relVel)).
        disp_info2("Current distance: " + round(target:position:mag, 1)).
    }
    translate().
    rcs_toggle_full_thrust(rcsList, false).
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
    lock steering to lookDirUp(-(tgtPort:portFacing:vector), tgtPort:ship:facing:foreVector).

    until ctrlPort:state <> "ready" 
    {
        translate((approachVec:normalized * spd) - relVel).
        local distVec to (tgtPort:nodePosition - ctrlPort:nodePosition).
        if vang(ctrlPort:portFacing:vector, distVec) < 2 and abs(dist - distVec:mag) < 0.1 
        {
            break.
        }
        wait 0.01.
        disp_info2("Current distance: " + round(target:position:mag, 1)).
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
    lock steering to lookDirUp(-(tgtPort:portFacing:vector), tgtPort:ship:facing:foreVector).

    until false 
    {
        translate((departVec:normalized * spd) - relVel).
        if departVec:mag < 0.1 
        {
            break.
        }
        wait 0.01.
        disp_info2("Current distance: " + round(target:position:mag, 1)).
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
    lock steering to lookDirUp(-(tgtPort:portFacing:vector), tgtPort:ship:facing:foreVector).

    until false 
    {
        translate((approachVec:normalized * spd) - relVel).
        if approachVec:mag < 0.1
        {
            break.
        }
        wait 0.01.
        disp_info2("Current distance: " + round(target:position:mag, 1)).
    }
}

global function rcs_toggle_full_thrust
{
    parameter rcsParts,
              state is true.

    for r in rcsParts
    {
        set r:fullThrust to state.
    }
}

global function rcs_set_deadband
{
    parameter rcsParts, 
              deadband to 0.01.

    for r in rcsParts
    {
        set r:deadband to deadband.
    }
}

global function rdz_select_probe_port
{
    if ship:partsTagged("probePort"):length = 1 
    {
        return ship:partsTagged("probePort")[0].
    }
    else if ship:dockingPorts:length = 1
    { 
        return ship:dockingPorts[0].
    }
    else if ship:dockingPorts:length > 1
    {
        disp_msg("Select probe port").
        return util_select_port(ship:dockingports).
    }
    else
    {
        disp_tee("No docking port on vessel!", 2).
        return 1 / 0.
    }
}

global function rdz_select_docking_target
{
    local selectedPort to "".

    if not hasTarget {
        disp_msg("Select a target for docking").
        until hasTarget
        {
            wait 0.01.
        }
    }
    
    if target:typeName = "Vessel"
    {
        disp_msg("Target vessel selected: " + target:name).
        wait 1.
        if target:dockingports:length > 1 
        {
            disp_msg("Select target port").
            set selectedPort to util_select_port(target:dockingPorts).
        }
        else if target:dockingPorts:length = 1
        {
            set selectedPort to target:dockingPorts[0].
            if selectedPort:state = "Ready" 
            {
                if not probePort:name = selectedPort:name
                {
                    disp_tee("Target port does not match probePort", 2).
                }
            }
            else 
            {
                disp_tee("Target port is not available", 2).
                return 1 / 0.
            }
        }
        else
        {
            disp_tee("Target has no docking port").
            return 1 / 0.
        }
    }
    else if target:typeName = "dockingPort"
    {
        set selectedPort to target.
    }
    else
    {
        disp_tee("Not a valid target type").
        return 1 / 0.
    }

    disp_msg("Target port selected").
    disp_info("Name: '" + selectedPort:name + "' Tag: '" + selectedPort:tag + "'").
    wait 1.
    return selectedPort.
}

global function util_select_port 
{
    parameter portList.
    
    local keyIdx to 0.
    local portIdx to 0.
    local portKeyList to list().
    local validPortList to list().

    for p in portList
    {
        if p:state = "Ready" 
        {
            print "[" + (keyIdx) + "][" + colorStr[keyIdx] + "] (" + p:name + ") | (" + p:tag + ")  " at (0, 10 + keyIdx).
            highlight(p, colors[keyIdx]).
            portKeyList:add(keyIdx:tostring).
            validPortList:add(p).
            set keyIdx to keyIdx + 1.
        }
    }
    
    disp_info("Select:").
    
    until false
    {
        set portIdx to util_wait_on_char().
        if not portKeyList:contains(portIdx)
        {
            disp_info("Invalid Selection: " + portIdx).
            set portIdx to "".
            wait 1.
            disp_info("Select:").
        }
        else
        {
            disp_msg("Selected: " + portIdx).
            break.
        }
    }

    set keyIdx to 0.
    for p in portList
    {
        print "                                                       " at (0, 10 + keyIdx).
        local hl to highlight(p, black).
        set hl:enabled to false.
        set keyIdx to keyIdx + 1.
    }

    return validPortList[portIdx:tonumber].
}