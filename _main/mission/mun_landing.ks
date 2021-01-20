runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_sci").

update_display().

out_msg("Compiling landing script to local drive").
compile("0:/_adhoc/land_on_mun") to "1:/land_on_mun".

// local tStamp to time:seconds + (ship:orbit:period / 1.85).
out_msg("Press any key to start landing sequence").
breakpoint().

out_msg("Running landing script").
runpath("1:/land_on_mun", 0, 0).
unlock steering.

out_msg("Doing science").
local sciMod to get_sci_list(ship:parts).
log_sci_list(sciMod).
recover_sci_list(sciMod).
