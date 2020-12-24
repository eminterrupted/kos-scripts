@lazyGlobal off.

parameter rm is 0,
          sr is "".

local stateObj is readJson("local:/state.json").
set stateObj:runmode to rm.
set stateObj:subroutine to sr.

writeJson(stateObj, "local:/state.json").