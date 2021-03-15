@lazyGlobal off.

runOncePath("0:/lib/lib_vessel").

local engCache to ves_engine_stage_obj().

local massCache to ves_mass_stage_cache().
print massCache.
writeJson(massCache, "1:/massCache.json").

print "Mass at next stage:".
print ves_mass_at_stage_next(stage:number).

print engCache.