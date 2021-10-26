print "Setting up return plan".

if not (exists("/boot/bootLoader.ks")) copyPath("0:/boot/bootLoader.ks", "/boot/bootLoader.ks").
set core:bootfilename to "/boot/bootLoader.ks".

writeJson(queue(
    "/return/return_from_mun",
    "return/reentry"
), "data_0:/missionPlan.json").

reboot.