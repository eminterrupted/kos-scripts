@LazyGlobal off.
clearScreen.

local variantTag to "".
local setupScript to path("0:/_plan/csat/setup_deployed.ks").

if core:tag:split(":"):length > 2 
{
    set variantTag to core:tag:split(":")[2].
    set core:tag to "csat:deployed:" + variantTag + core:tag:substring(core:tag:length - 2, 2).
    set setupScript to setupScript:changeName("setup_deployed_" + variantTag + ".ks").
}
else if core:tag:length > 0
{
    set variantTag to core:tag.
    set core:tag to "csat:deployed:" + variantTag + "|0".
    set setupScript to setupScript:changeName("setup_deployed_" + variantTag + ".ks").
}
else
{
    set core:tag to "csat:deployed|0".
}

copyPath("0:/boot/_bl.ks", "/boot/_bl.ks").
set core:bootfilename to "/boot/_bl.ks".
runPath(setupScript).

for p in ship:partsTagged("doNotDeploy") set p:tag to "".

set ship:name to ship:name:replace(" probe", "") + variantTag.
writeJson(list(ship:name), "vessel.json").

reboot.