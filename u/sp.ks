@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_sci").

local sciMod to get_sci_mod_for_parts(ship:parts).

clearScreen.

from { local n to 0.} until n = 5 step { set n to n + 1.} do {
    print n at (2, 10).
    wait 1.
}

log_sci_list(sciMod).

recover_sci_list(sciMod).

transmit_when_avail().
