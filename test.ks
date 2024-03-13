ClearScreen.

parameter fooMask to "111111111111".

RunOncePath("0:/lib/depLoader").

set g_line to 2.

print "[Bitmask parsing test]" at (0, g_line).

print "Bitmask length: {0}":Format(fooMask:Length) at (0, cr()).

print "String parsing method" at (0, cr(g_line + 2)).
print "---------------------" at (0, cr()).


set avgPassUTime to 0.00000000000001.
set avgPassRTime to 0.00000000000001.

set avgFullUTime to 0.00000000000001.
set avgFullRTime to 0.00000000000001.

set ts_RT_L0 to 0.
set ts_RT_L1 to 0.

set ts_UT_L0 to 0.
set ts_UT_L1 to 0.

set rtAvgPassTracker to list().
set rtAvgFullTracker to list().

set utAvgPassTracker to list().
set utAvgFullTracker to list().

local testRange to Range(0, 9, 1).

local startLine to cr(g_line + 1).

for rng in testRange
{
    set g_line to startLine.

    set ts_UT_L0 to Time:Seconds.
    set ts_RT_L0 to Kuniverse:RealTime.

    from { local i to 0. } until i = fooMask:Length step { set i to i + 1.} do 
    {
        set ts_UT_L1 to Time:Seconds.
        set ts_RT_L1 to Kuniverse:RealTime.

        set _c to fooMask[i]:ToNumber(0).
        if _c 
        { 
            print "[{0}] {1}":Format(i, _c) at (2, cr()).
            
        }

        utAvgPassTracker:Add(Time:Seconds - ts_UT_L1).
        rtAvgPassTracker:Add(Kuniverse:RealTime - ts_RT_L1).
    }

    utAvgFullTracker:Add(Time:Seconds - ts_UT_L0).
    rtAvgFullTracker:Add(KUniverse:RealTime - ts_RT_L0).
}

from { local i to 0.} until i = utAvgPassTracker:Length step { set i to i + 1.} do 
{
    set avgPassUTime to avgPassUTime + utAvgPassTracker[i].
    set avgPassRTime to avgPassRTime + rtAvgPassTracker[i].
}
set avgPassUTime to avgPassUTime / utAvgPassTracker:Length.
set avgPassRTime to avgPassRTime / rtAvgPassTracker:Length.

from { local i to 0.} until i = utAvgFullTracker:Length step { set i to i + 1.} do 
{
    set avgFullUTime to avgFullUTime + utAvgFullTracker[i].
    set avgFullRTime to avgFullRTime + rtAvgFullTracker[i].
}
set avgFullUTime to avgFullUTime / utAvgFullTracker:Length.
set avgFullRTime to avgFullRTime / rtAvgFullTracker:Length.

print "String parsing: " at (0, cr(g_line + 2)).

print "Per-Char averages" at (0, cr(g_line + 1)).
print "Char UTime : {0}s":Format(Round(avgPassUTime, 7)) at (2, cr()).
print "Char RTime : {0}s":Format(Round(avgPassRTime, 7)) at (2, cr()).

print "Full-pass averages" at (0, cr(g_line + 1)).
print "Full UTime : {0}s":Format(Round(avgFullUTime, 7)) at (2, cr()).
print "Full RTime : {0}s":Format(Round(avgFullRTime, 7)) at (2, cr()).


print "List parsing method" at (0, cr(g_line + 3)).
print "-------------------" at (0, cr()).

set fooList to list().
set _c to "".

set avgFullUTime to 0.00000000000001.
set avgFullRTime to 0.00000000000001.

set avgPassUTime to 0.00000000000001.
set avgPassRTime to 0.00000000000001.

set ts_UT_L0 to Time:Seconds.
set ts_RT_L0 to Kuniverse:RealTime.

set ts_RT_L0 to 0.
set ts_RT_L1 to 0.

set ts_UT_L0 to 0.
set ts_UT_L1 to 0.

set rtAvgPassTracker to list().
set rtAvgFullTracker to list().

set utAvgPassTracker to list().
set utAvgFullTracker to list().

set startLine to cr(g_line + 1).

set _c to "".
for rng in testRange
{
    set g_line to startLine.

    set ts_UT_L0 to Time:Seconds.
    set ts_RT_L0 to Kuniverse:RealTime.
    
    set fooList to list().

    for chr in fooMask
    {
        fooList:Add(chr:ToNumber(0)).
    }

    from { local i to 0. } until i = fooList:Length step { set i to i + 1.} do 
    {
        set ts_UT_L1 to Time:Seconds.
        set ts_RT_L1 to Kuniverse:RealTime.

        set _c to fooList[i].
        if _c { 
            print "[{0}] {1}":Format(i, _c) at (2, cr()).
        }
        // else {
        //     print "[{0}] {1}":Format(i, _c).
        // }

        utAvgPassTracker:Add(Time:Seconds - ts_UT_L1).
        rtAvgPassTracker:Add(Kuniverse:RealTime - ts_RT_L1).
    }

    utAvgFullTracker:Add(Time:Seconds - ts_UT_L0).
    rtAvgFullTracker:Add(KUniverse:RealTime - ts_RT_L0).
}

from { local i to 0.} until i = utAvgPassTracker:Length step { set i to i + 1.} do 
{
    set avgPassUTime to avgPassUTime + utAvgPassTracker[i].
    set avgPassRTime to avgPassRTime + rtAvgPassTracker[i].
}
set avgPassUTime to avgPassUTime / utAvgPassTracker:Length.
set avgPassRTime to avgPassRTime / rtAvgPassTracker:Length.

from { local i to 0.} until i = utAvgFullTracker:Length step { set i to i + 1.} do {
    set avgFullUTime to avgFullUTime + utAvgFullTracker[i].
    set avgFullRTime to avgFullRTime + rtAvgFullTracker[i].
}
set avgFullUTime to avgFullUTime / utAvgFullTracker:Length.
set avgFullRTime to avgFullRTime / rtAvgFullTracker:Length.


// print " ".
print "list storing and parsing: " at (0, cr(g_line + 1)).
// print " ".
print "Per-Char averages" at (0, cr(g_line + 1)).
print "Char UTime : {0}s":Format(Round(avgPassUTime, 7)) at (2, cr()).
print "Char RTime : {0}s":Format(Round(avgPassRTime, 7)) at (2, cr()).
// print " ".
print "Full-pass averages" at (0, cr(g_line + 1)).
print "Full UTime : {0}s":Format(Round(avgFullUTime, 7)) at (2, cr()).
print "Full RTime : {0}s":Format(Round(avgFullRTime, 7)) at (2, cr()).
cr(g_line).
print "*** Complete ***" at (0, cr()).