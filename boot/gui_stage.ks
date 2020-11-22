if ship:status = "PRELAUNCH" or ship:status = "LANDED"  runPath("0:/boot/launch_gui.ks").
else {
    local cache is readJson("local:/launchSelectCache.json").
    local localMC is "local:/mc.ks".
    local kscMC is "archive:/_main/mc.ks".

    if exists(localMC) runPath(localMC, cache["launchScript"], cache["missionScript"], cache["tApo"], cache["tPe"], cache["tInc"], cache["gtAlt"], cache["gtPitch"]).
    else if addons:rt:haskscconnection runPath(kscMC, cache["launchScript"], cache["missionScript"], cache["tApo"], cache["tPe"], cache["tInc"], cache["gtAlt"], cache["gtPitch"]).
    else print "No scripts found, aborting boot".
}
