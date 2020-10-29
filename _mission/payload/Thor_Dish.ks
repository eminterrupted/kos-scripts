@lazyGlobal off.

runOncePath("0:/lib/part/lib_antenna.ks").
runOncePath("0:/lib/part/lib_dish.ks").

local dList is ship:partsTaggedPattern("dish").

for p in dList {
    local dishData is get_antenna_fields(p).
    if dishData:target = "no-target" set_dish_target(p, "mun").
    
    activate_antenna(p).
}