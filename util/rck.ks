@lazyGlobal off.

parameter key.

local dataDisk    to "local:/".
for c in ship:modulesNamed("kosProcessor")
{
    if c:volume:name = "data_0" set dataDisk to "data_0:/".
}
local stateFile     to dataDisk + "state.json".
local state         to readJson(stateFile).

state:remove(key).

writeJson(state, stateFile).

if not readJson(stateFile):hasKey(key)
{
    print "Key [" + key + "] reset".
}
else 
{
    print "ERR: Key [" + key + "] still present in state file".
    print readJson(stateFile).
}