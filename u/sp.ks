runOncePath("0:/lib/lib_sci_next").

clearScreen.

wait 1.

set sList to get_sci_mod_for_parts(ship:parts).

print sList at (2, 20).