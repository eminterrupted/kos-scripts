@lazyGlobal off.

runOncePath("0:/lib/lib_mnv").

parameter param.

local ts to time:seconds.
print "Burn duration for " + param + "dV: " + mnv_burn_dur(param).
print "Function time delta: " + (time:seconds - ts).