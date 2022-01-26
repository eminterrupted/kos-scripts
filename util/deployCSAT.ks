@LazyGlobal off.
clearScreen.

RunOncePath("0:/lib/disp").

DispMain(ScriptPath(), false).

local setupScript to path("0:/_plan/csat/setup_deployed.ks").
local stageTag to stage:number.
local variantTag to "".

OutMsg("Parsing core tag: " + core:tag).
if core:tag:split(":"):length > 2 
{
    set variantTag to core:tag:split(":")[2].
    OutInfo("Variant Tag: " + variantTag).
    if variantTag:contains("|")
    {
        OutInfo("Removing stageTag(s)").
        until not variantTag:contains("|")
        {
            set stageTag to variantTag:split("|")[1].
            set variantTag to variantTag:replace("|" + stageTag, "").
            if stageTag > stage:number set stageTag to 0.
            OutInfo("Variant Tag: " + variantTag).
            wait 0.25.
        }
    }
    set core:tag to "csat:deployed:" + variantTag + "|" + stageTag.
    set setupScript to setupScript:changeName("setup_deployed_" + variantTag + ".ks").
}
else if core:tag:length > 0
{
    set variantTag to core:tag:replace("[",""):replace("]","").
    OutInfo("Variant Tag: " + variantTag).
    if variantTag:contains("|")
    {
        OutInfo("Parsing stageTag(s)").
        until not variantTag:contains("|")
        {
            set stageTag to variantTag:split("|")[1].
            set variantTag to variantTag:replace("|" + stageTag, "").
            if stageTag > stage:number set stageTag to 0.
            OutInfo("Variant Tag: " + variantTag).
            wait 0.25.
        }
    }
    set core:tag to "csat:deployed:" + variantTag + "|" + stageTag.
    set setupScript to setupScript:changeName("setup_deployed_" + variantTag + ".ks").
}
else
{
    set core:tag to "csat:deployed|0".
}
OutInfo().
OutInfo2().
OutMsg("Core tag parsed: " + core:tag).

copyPath("0:/boot/_bl.ks", "/boot/_bl.ks").
set core:bootfilename to "/boot/_bl.ks".
runPath(setupScript).

for p in ship:partsTagged("doNotDeploy") set p:tag to "".

set ship:name to ship:name:replace(" probe", "") + variantTag.
writeJson(list(ship:name), "vessel.json").

reboot.