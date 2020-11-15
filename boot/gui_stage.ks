if ship:status = "PRELAUNCH" or ship:status = "LANDED"  runPath("0:/boot/launch_gui.ks").
else {
    local cache is readJson("local:/launchSelectCache.json").
    local localMC is "local:/mission_controller.ks".
    local kscMC is "archive:/_main/mission_controller.ks".

    if exists(localMC) runPath(localMC, cache["launchScript"], cache["missionScript"], cache["tApo"], cache["tPe"], cache["tInc"], cache["gtAlt"], cache["gtPitch"]).
    else runPath(kscMC, cache["launchScript"], cache["missionScript"], cache["tApo"], cache["tPe"], cache["tInc"], cache["gtAlt"], cache["gtPitch"]).
}
