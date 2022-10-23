@lazyGlobal off.
ClearScreen.

parameter doReturn is false.

RunOncePath("0:/lib/disp").

DispMain(ScriptPath()).
local setupScript is "".
local curTag to choose ":" + core:tag if core:tag:length > 0 else "".

if doReturn
{
    set setupScript to choose Path("0:/_plan/lander/setup_atm_returnToOrbit.ks") if ship:body:atm:exists else Path("0:/_plan/lander/setup_returnToOrbit.ks").
    set core:tag to "lander:returnToOrbit" + curTag + "|0".
}
else
{
    set setupScript to choose Path("0:/_plan/lander/setup_atm.ks") if ship:body:atm:exists else Path("0:/_plan/lander/setup.ks").
    set core:tag to "lander:simple" + curTag + "|0".
}

copyPath("0:/boot/_bl.ks", "/boot/_bl.ks").
set core:bootfilename to "/boot/_bl.ks".
runPath(setupScript).

// if core:tag:split(":"):length > 3 
// {
//     set ship:name to ship:name + " (" + core:tag:split(":")[3] + ")".
// }
writeJson(list(ship:name), "vessel.json").

reboot.