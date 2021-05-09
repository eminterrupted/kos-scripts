@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_test").
runOncePath("0:/lib/lib_util").

// Check for addon dependencies
if addons:career:available runOncePath("0:/lib/lib_addon_career").

// Main
test_pad_gen(true).
test_lights(true).

local msgLine   to 0.
local tested    to list().
local pList     to list().
local sciList   to sci_modules().

set terminal:width to 60.
core:doAction("open terminal", true).

// Part testing
for p in ship:parts
{
    if p:hasModule("ModuleTestSubject") or p:tag = "test" or p:typeName = "engine"
    {
        pList:add(p).
    }
}

set pList to util_order_list_by_stage(pList, "desc").

for testPart in pList
{
    if not tested:contains(testPart) 
    {
        set msgLine to test_part_info(testPart).
        local ts to time:seconds + 3.
            until time:seconds >= ts
            {
                print "Countdown to test: " + round(time:seconds - ts) + " " at (2, msgLine).
                wait 1.
            }
        print ("Test in progress..."):padRight(terminal:width) at (2, msgLine).
        test_part(testPart). // activates the part
        print ("Test complete"):padRight(terminal:width) at (2, msgLine).
        wait 1.
    }
    for p in ship:parts
    {
        if p:stage = stage:number
        {
            tested:add(p).
            print tested at (2, 15).
        }
    }
    if stage = 0 break.
}

// Science testing
if sciList:length > 0 
{
    print ("Running science experiments"):padRight(terminal:width) at (2, msgLine).
    sci_deploy_list(sciList).
}

test_lights(false).
test_pad_gen(false).
clearScreen.
print "All tests complete!".
// End main