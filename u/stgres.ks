@lazyGlobal off.

clearscreen.

local ln to 10. 
local n to 0. 
    print "Resource" at (10, ln).
    print "--------" at (10, ln + 1).
  
    print "Pct" at (35, ln).
    print "---" at (35, ln + 1).

    print "Amount" at (45, ln).
    print "------" at (45, ln + 1).

    print "Capacity" at (55, ln).
    print "--------" at (55, ln + 1).

    set ln to ln + 2.

    for r in stage:resources {
        local pct to choose 0 if r:amount <= 0 else r:amount / r:capacity.

        print "R[" + n + "]: " + r:name at (2, ln).
        print round(pct, 2) + "%   " at (35, ln).
        print round(r:amount, 2) at (45, ln). 
        print round(r:capacity, 2) at (55, ln).
    
    set n to n + 1. set ln to ln + 1.
    
    if ln >= 75 {
        print "*** Press any key to continue ***" at (10, ln + 1).
        terminal:input:getChar().
        clearscreen.
        set ln to 0.
    }
}