@lazyGlobal off.

runOncePath("0:/lib/lib_test").
runOncePath("0:/lib/lib_util").

global line     to 0.

local testList  to list().
local testType  to "haul".

local tgtAltLow_0  to 4000.
local tgtAltHigh_0 to 9000.
local tgtSpdLow_0  to 370.
local tgtSpdHigh_0 to 550.
lock  altRange_0   to util_check_range(ship:altitude, tgtAltLow_0, tgtAltHigh_0). 
lock  spdRange_0   to util_check_range(ship:velocity:surface:mag, tgtSpdLow_0, tgtSpdHigh_0).

local tgtAltLow_1  to 16000.
local tgtAltHigh_1 to 26000.
local tgtSpdLow_1  to 1560.
local tgtSpdHigh_1 to 1890.
lock  altRange_1   to util_check_range(ship:altitude, tgtAltLow_1, tgtAltHigh_1). 
lock  spdRange_1   to util_check_range(ship:velocity:surface:mag, tgtSpdLow_1, tgtSpdHigh_1).

if ship:modulesNamed("ModuleTestSubject"):length > 0 
{
    for m in ship:modulesNamed("ModuleTestSubject")
    {
        testList:add(m:part).
    }
}

if ship:partsTaggedPattern("test"):length > 0
{
    for p in ship:partsTaggedPattern("test")
    {
        testList:add(p).
    }
}

util_sort_list_by_stage(testList, "asc").

print "Test telemetry" at (0, 8).
print "--------------" at (0, 9).
until false {
    set line to 10.
    print "Mission time      : " + round(missionTime) at (0, cr()).
    cr().
    print "Test Part         : " + testList[0]:title + "   " at (0, cr()).
    print "Altitude range met: " + altRange_0 + "   " at (0, cr()).
    print "Speed range met   : " + spdRange_0 + "   " at (0, cr()).
    cr().
    print "Test Part         : " + testList[1]:title + "   " at (0, cr()).
    print "Altitude range met: " + altRange_1 + "   " at (0, cr()).
    print "Speed range met   : " + spdRange_1 + "   " at (0, cr()).
}

if testType <> "haul" 
{
    when altRange_0 then
    {
        if spdRange_0
        {
            test_part(testList[0]).
        }
    }

    when altRange_1 then
    {
        if spdRange_1
        {
            test_part(testList[1]).
        }
    }
}

local function cr 
{
    set line to line + 1.
    return line.
}