@lazyGlobal off.

parameter key.

local dataDisk      to choose "data_0:/" if exists(volume("data_0")) else "local:/".
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