@lazyGlobal off.

runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

// Variables
local refBays to list().
local roboticMods to list().
local vesBays to uniqueSet().

// Main
set roboticMods to ves_get_robotics().
set refBays to list(
    "service-tank-25"
).

// Bays
// All US bays
if ship:partsNamedPattern("USCylindricalShroud"):length > 0
{
    for m in ves_get_us_bays()
    {
        if m:part:tag:contains("panel") vesBays:add(m).
        else if m:part:tag:contains("launch") vesBays:add(m).
    }
}

for p in ship:parts
{
    if refBays:contains(p:name) 
    {
        if p:tag:contains("panel") or p:tag:contains("launch")
        {
            vesBays:add(p:getModule("ModuleAnimateGeneric")).
        }
    }
}
ves_open_bays(vesBays).

// Solar panels
for m in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = ""
    {
        if m:part <> ship:rootpart 
        {
            if m:part:parent:name:contains("hinge") 
            {
                local hingeMod to m:part:parent:getModule("ModuleRoboticServoHinge").
                util_do_action(hingeMod, "toggle hinge").
                wait max(5, abs((hingeMod:getField("target angle") - hingeMod:getField("current angle")) / hingeMod:getField("traverse rate"))).
            }
        }
        util_do_event(m, "extend solar panel").   
    }
}
   
// Antennas
for m in ship:modulesNamed("ModuleRTAntenna")
{       
    if m:part:tag = "" 
    {
        if m:part <> ship:rootpart 
        {
            if m:part:parent:name:contains("hinge") 
            {
                local hingeMod to m:part:parent:getModule("ModuleRoboticServoHinge").
                util_do_action(hingeMod, "toggle hinge").
                wait max(5, abs((hingeMod:getField("target angle") - hingeMod:getField("current angle")) / hingeMod:getField("traverse rate"))).
            }
            util_do_event(m, "activate").
        }
    }
}

local stgComms to ship:partsTaggedPattern("stageAntenna").

if stgComms:length > 0 
{
    local stgCommMods to list().
    for p in stgComms 
    {
        stgCommMods:add(p:getModule("ModuleRTAntenna")).
    }
    ves_antenna_stage_trigger(stgCommMods).
}