@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_test").
runOncePath("0:/lib/lib_util").

// Check for addon dependencies
if addons:career:available runOncePath("0:/lib/lib_addon_career").

// Main
test_stand_gen(true).
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
    print ("Test in progress..."):padRight(terminal:width) at (2, msgLine).
    test_part(p). // activates the part
    print ("Test complete"):padRight(terminal:width) at (2, msgLine).
    wait 3.
}

// Science testing
if sciList:length > 0 
{
    for m in sciList {
        set msgLine to test_part_info(m:part).
        print ("Running science experiments"):padRight(terminal:width) at (2, msgLine).
        sci_deploy(m).
        wait until m:hasData.
        wait 3.
    }
}

test_lights(false).
test_stand_gen(false).
wait 1.
clearScreen.
print "All tests complete!".
// End main