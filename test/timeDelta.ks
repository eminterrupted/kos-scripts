clearScreen.

local tRef is time.
local rRef is kuniverse:realtime.

print "Game Time Start: " + tRef at(2, 10).
print "Real Time Start: " + rRef at(2, 11).

local function printTime {
    set t0 to time.
    set r0 to kuniverse:realtime.
    print "Game Time: " + t0 + "    " at(2, 13).
    print "Real Time: " + round(r0, 0) + "    " at(2, 14).

    return r0.
}

until time - tRef > 10 {
    set rD to printTime().
    wait 0.01. 
}

print "Total Time delta: " + (rD - rRef) at (2, 16).
print "Delta per game s: " + ((rD - rRef) / 10) at (2, 17).