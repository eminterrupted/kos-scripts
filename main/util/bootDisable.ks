@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

local mp to list().
local mpPath to choose mpLoc if defined mpLoc else Path("mp.json").
local mpBak to "1:/bak/mp.json".

if params:length > 0 
{
    set mpPath to params[0].
}

if exists(path(mpPath))
{
    set mp to readJson(mpPath).
}
else if homeConnection:isConnected
{
    if exists(path(mpArc))
    {
        set mp to readJson(mpArc).
    }
}
if mp[0] = "util/bootDisable" 
{
    mp:remove(1).
    mp:remove(0).
}

writeJson(mp, mpBak).
if exists(mpBak)
{
    copyPath(mpBak, mpArc).
    deletePath(mpPath).
    OutMsg("mp.json moved to /mpBak/mp.json").
}
wait 0.01.

set core:bootFileName to "".
OutMsg("Bootloader cleared, run '0:/util/rb' to reenable").
local ts to time:seconds + 5.
OutTee("Rebooting core {0} in {1}s":format(core:tag, round((ts - time:seconds))), 1).

until time:seconds >= ts 
{
    OutInfo("Rebooting in {0}s":format(round((ts - time:seconds), 2))).
    wait 0.05.
}
OutInfo().
OutHUD("Rebooting {0} now...":format(core:tag)).
clearscreen.
reboot.