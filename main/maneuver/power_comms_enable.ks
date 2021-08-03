@lazyGlobal off.

runOncePath("0:/lib/lib_vessel").

local event to "extend solar panel".

for m in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = ""
    {
        if m:hasEvent(event) m:doEvent(event).
    }
}
   
for m in ship:modulesNamed("ModuleRTAntenna")
{       
    if m:part:tag = "" 
    {
        if m:hasEvent("activate") m:doEvent("activate"). 
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