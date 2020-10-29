@lazyGlobal off.

runOncePath("0:/lib/part/lib_antenna.ks").
runOncePath("0:/lib/part/lib_dish.ks").

local p is ship:partsTaggedPattern("dish")[0].
local dishData is get_antenna_fields(p).

if dishData:target = "no-target" set_dish_target(p, "mun").

activate_antenna(p).