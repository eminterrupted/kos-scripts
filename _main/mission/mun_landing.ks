runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_sci").

local landingPath to "1:/land_on_mun".

update_display().

out_msg("Compiling landing script to local drive").
local script to "0:/a/land_on_mun".
if exists(landingPath) 
{
    deletePath(landingPath).
}
compile(script) to landingPath.

lock steering to ship:retrograde.

// local tStamp to time:seconds + (ship:orbit:period / 1.85).
if ship:altitude > 10000 
{
    out_msg("Press any key to start landing sequence").
    breakpoint().
}

out_msg("Running landing script").
runpath(landingPath, 0, 0).
unlock steering.

out_msg("Doing surface science").
local sciMod to get_sci_list(ship:parts).

out_info("Deploying experiments").
deploy_sci_list(sciMod).
wait 3.

if ship:partsTaggedPattern("seismicPod"):length > 0 
{
    out_info("Deploying seismic pods").
    deploy_seismic_pods().
    set sciMod to get_sci_mod().
}

out_info("Logging results of experiments").
log_sci_list(sciMod).
wait 3.

out_info("Recovering data from experiments").
recover_sci_list(sciMod).
wait 3.

out_msg("Landing mission complete!").
out_info().
deletePath(landingPath).