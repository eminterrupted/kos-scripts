@lazyGlobal off.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").

// Main
test_lights(true).

local msgLine   to 0.
local pList     to list().
local sciList   to sci_modules().

set terminal:width to 60.
core:doAction("open terminal", true).

// Part testing
for p in ship:parts
{
    if p:hasModule("ModuleTestSubject") or p:tag:contains("test")
    {
        pList:add(p).
    }
}

set pList to util_sort_list_by_stage(pList, "desc").
for p in pList
{
    set msgLine to test_part_info(p).
    local ts to time:seconds + 5.
    until time:seconds >= ts
    {
        print "Countdown to test: " + round(time:seconds - ts) + " " at (2, msgLine).
        wait 1.
    }

    stage. // activates the part
    padRight("Test in progress...", msgLine).
    
    if ship:maxthrust > 0 
    {
        test_engine(p, 15). 
    }

    padRight("Test complete", msgLine).
    wait 3.
}

// Science testing
if sciList:length > 0 
{
    for m in sciList {
        set msgLine to test_part_info(m:part).
        padRight("Running science experiments", msgLine).
        sci_deploy(m).
        wait until m:hasData.
        wait 3.
    }
}

test_lights(false).
clearScreen.
print "All tests complete!".
// End main

//-- Local test functions --//

    // Displays engine characteristics during a test
    local function test_engine 
    {
        parameter p, 
                  dur is 15, 
                  line is 8.

        lock throttle to 1.
        until dur <= 0 and p:thrust <= 0.1
        {
            print "Engine Performance Data"                                                    at (2, line).
            print "-----------------------"                                                    at (2, line + 1).
            print ("SL THRUST : " + round(p:thrust, 2)):padRight(terminal:width)               at (2, line + 2).
            print ("SL ISP    : " + round(p:sealevelIsp, 2)):padRight(terminal:width)          at (2, line + 3).
            print ("VAC THRUST: " + round(p:availableThrustAt(0), 2)):padRight(terminal:width) at (2, line + 4).
            print ("VAC ISP   : " + round(p:vacuumIsp, 2)):padRight(terminal:width)            at (2, line + 5).
            print ("FUEL FLOW : " + round(p:fuelFlow, 5)):padRight(terminal:width)             at (2, line + 6).

            set dur to dur - 1.
            wait 1.
        }
        lock throttle to 0.

        from { local cr to line.} until cr = line + 7 step { set cr to cr + 1.} do 
        {
            disp_clr(cr).
        }
    }

    // Turns on / off any lights present
    local function test_lights
    {
        parameter state.

        if ship:modulesNamed("ModuleLight"):length > 0
        {
            for m in ship:modulesNamed("ModuleLight")
            {
                if state util_do_event(m, "lights on").
                else     util_do_event(m, "lights off").
            }
        }
    }

    // Takes a module and displays test subject info
    local function test_part_info
    {
        parameter p.

        clearScreen.
        print "Test Controller v0.01b" at (2, 2).
        print "----------------------" at (2, 3).
        
        print ("Test Part    : " + p:title):padRight(terminal:width) at (2, 5).
        print ("Part NameId  : " + p:name):padRight(terminal:width) at (2, 6). 
        
        return 8.
    }