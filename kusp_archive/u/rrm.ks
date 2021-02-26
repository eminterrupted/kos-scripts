@lazyGlobal off.

parameter rm is 0,
          sr is "".

runOncePath("0:/lib/lib_init").

set stateObj:runmode to rm.
set stateObj:subroutine to sr.

writeJson(stateObj, "local:/state.json").