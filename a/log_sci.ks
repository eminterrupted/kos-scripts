@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_bays").
runOncePath("0:/lib/lib_display").

out_msg("Opening bay doors").
for p in ship:partsTaggedPattern("bay.doors") 
{
    deploy_bay_doors(p).
}

out_msg("Doing surface science").
local sciMod to get_sci_list(ship:parts).

out_msg("Deploying experiments").
deploy_sci_list(sciMod).
wait 3.

if ship:partsTaggedPattern("seismicPod"):length > 0 
{
    out_msg("Deploying seismic pods").
    deploy_seismic_pods().
    set sciMod to get_sci_mod().
}

out_msg("Logging results of experiments").
log_sci_list(sciMod).
wait 3.

out_msg("Recovering data from experiments").
recover_sci_list(sciMod).
wait 3.