@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_engine_data").
runOncePath("0:/lib/part/lib_solar").
runOncePath("0:/lib/part/lib_antenna").

local tdList to ship:partsTaggedPattern("onTouchdown").

for p in tdList {
    if p:tag:contains ("solar") {
        deactivate_solar(p).
    } else if p:tag:contains("omni") {
        deactivate_omni(p).
    }
    set p:tag to p:tag:replace(".onTouchdown", "").
}

local curEngs to engs_for_next_stg().
for eng in curEngs {
    eng:activate.
}

for f in volume("local"):files:keys {
    deletePath(f).
}