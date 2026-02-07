@lazyGlobal off.
clearscreen.

local loopCount to 3.

// First command below
print "CSet1x (Concat)" + loopCount.
local timer to 0.
from { local tgtList is list(). list Targets in tgtList. local i to 0.} until i = loopCount step { set i to i + 1.} do 
{
    print tgtList[i].
    set timer to Time:Seconds.
    print "Timer: " + timer.
}

// Reset
unset timer.
print " ".
print " ".

// Second command below
print "CSet2x{0} (Format)":Format(loopCount).
local timer to 0.
from { local i to 0.} until i = loopCount step { set i to i + 1.} do 
{
    set timer to Time:Seconds.
    print "Timer: {0}":Format(timer).
}

// Reset
unset timer.
print " ".
print " ".

// First command below
print "CSet1x (From Declare, Concat)" + loopCount.
from { local timer to 0. local i to 0.} until i = loopCount step { set i to i + 1.} do 
{
    set timer to Time:Seconds.
    print "Timer: " + timer.
}

// Reset
print " ".
print " ".

// Second command below
print "CSet4x{0} (From Declare, Format)":Format(loopCount).
from { local timer to 0. local i to 0.} until i = loopCount step { set i to i + 1.} do 
{
    set timer to Time:Seconds.
    print "Timer: {0}":Format(timer).
}

// Reset
print " ".
print " ".
