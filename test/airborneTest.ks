@lazyGlobal off.
clearscreen. 

local line     to 0.

runOncePath("0:/lib/lib_test").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_disp").


local partStatus to lex().
local testLex    to lex().
local testList   to list().
//local testType   to "stage".

// Set up the display
disp_terminal().
disp_main(scriptPath():name).

if ship:partsTaggedPattern("test"):length > 0
{
    for p in ship:partsTaggedPattern("test")
    {
        testList:add(p).
    }
}

util_order_list_by_stage(testList, "asc").

for p in testList
{
    set partStatus to lex(p:name, false).
    set testLex[p:name] to lex("p", p).
    local pTagSplit to p:tag:split(";").
    for t in pTagSplit
    {

        if t:startsWith("alt_") 
        {
            set testLex[p:name]["alt"] to list().
            for altTag in t:replace("alt_",""):split(":")
            {
                testLex[p:name]["alt"]:add(altTag:toNumber * 1000).
            }
        }
        else if t:startsWith("vel_") 
        {
            set testLex[p:name]["vel"] to list().
            for velTag in t:replace("vel_",""):split(":") 
            {
                testLex[p:name]["vel"]:add(velTag:toNumber).
            }
        }
    }
}

local testStatus is list().
print "Test telemetry" at (0, 8).
print "--------------" at (0, 9).
until false {
    set line to 10.
    print "Mission time      : " + round(missionTime) at (0, cr()).
    cr().
    for p in testLex:keys
    {
        local altCheck to util_check_range(ship:altitude, testLex[p]["alt"][0], testLex[p]["alt"][1]).
        local velCheck to util_check_range(ship:velocity:surface:mag, testLex[p]["vel"][0], testLex[p]["vel"][1]). 
        
        print "Test Part         : " + testLex[p]["p"]:title + "   " at (0, cr()).
        print "Altitude range met: " + altCheck + "   " at (0, cr()).
        print "Speed range met   : " + velCheck + "   " at (0, cr()).   
        if altCheck and velCheck and not testStatus:contains(p)
        {
            if p:stage = stage:number - 1 test_part(testLex[p]["p"]).
            testStatus:add(p).
        }
        cr().
    }
}

local function cr 
{
    set line to line + 1.
    return line.
}