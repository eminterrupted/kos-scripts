@lazyGlobal off.

parameter distThresh is 30000.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_bays").

local landingPath to "1:/land_on_mun".

update_display().

out_msg("Compiling landing script to local drive").
local script to "0:/a/land_on_mun".
if exists(landingPath) 
{
    deletePath(landingPath).
}
compile(script) to landingPath.

local wp to active_waypoint().

lock steering to ship:retrograde.

// local tStamp to time:seconds + (ship:orbit:period / 1.85).
if ship:altitude > 10000 
{
    out_msg("Waiting until distance target: " + distThresh).
    until wp:geoPosition:distance <= distThresh or ag10
    {
        update_display().
        disp_block(list(
            "distance",
            "waypoint info",
            "name", wp:name,
            "distance", round(wp:geoposition:distance),
            "eta", round(wp:geoposition:distance / groundSpeed)
        )).
        print "*** Press 0 to immediately trigger landing sequence ***" at (5, terminal:height - 5).
    }
    print "                                                        " at (5, terminal:height - 5).
    disp_clear_block("distance").
    // out_msg("Press any key to start landing sequence").
    // breakpoint().
}

out_msg("Running landing script").
runpath(landingPath, 0, 0).
unlock steering.

out_msg("Opening bay doors").
for p in ship:partsTaggedPattern("bay.doors") 
{
    deploy_bay_doors(p).
}

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