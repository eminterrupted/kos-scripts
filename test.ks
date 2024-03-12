RunOncePath("0:/lib/depLoader").

ClearScreen.

local fooEngs to GetShipEngines().
writeJson(fooEngs, "0:/test/fooEngs.json").
