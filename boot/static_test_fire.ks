@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/part/lib_launchpad").

local engList   to list().
local highStg   to 0.
local boostEngs to list().

update_display().
out_msg("Preparing static fire. Press any key to continue").
breakpoint().

// Get the engine with the highest stageId - this is our booster stage
list engines in engList.
for e in engList {
    local engStg    to get_stg_id_from_tag(e).
    if engStg > highStg {
        set highStg to engStg.
    }
}

// Collect all engines in the boost stage
set boostEngs to ship:partsTaggedPattern("eng.*.stgId:" + highStg).

// Set the tag to include test so that the testcontroller sees it
for e in boostEngs {
    set e:tag to e:tag + ".test".
}

// Perform the static fire
runpath("0:/_main/tc", boostEngs, "staticFire").

// Remove the test tag
for e in boostEngs {
    set e:tag to e:tag:replace(".test", "").
}

// TODO - Get the a tank in the same stage as the tested engine and monitor it during refueling
local tankMon to ship:partsTaggedPattern("tank.*.stgId:" + highStg)[0].
lock tankFill to tankMon:resources[0]:amount / tankMon:resources[0]:capacity.

// Refuel
update_display().
out_msg("Refueling...").
mlp_gen_on().
mlp_fuel_on().
until tankFill >= 1 {
    update_display().
    disp_block(
        list(
            "tankFill",
            "Refueling Status",
            "FuelType", tankMon:resources[0]:name,
            "Current", round(tankMon:resources[0]:amount, 2),
            "Capacity", round(tankMon:resources[0]:capacity, 2),
            " ", " ",
            "FuelType", tankMon:resources[1]:name,
            "Current", round(tankMon:resources[1]:amount, 2),
            "Capacity", round(tankMon:resources[1]:capacity, 2)
        )
    ).
}
wait 1.
mlp_fuel_off().
mlp_gen_off().

update_display().
out_msg("Refueling complete!").
wait 1.
clearScreen.