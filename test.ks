RunOncePath("0:/lib/depLoader").

local foo to GetMissionPlan(ListMissionPlans()[0]).
WriteJson(foo, "0:/data/fooNew.json").
print ReadJson("0:/data/fooNew.json").
