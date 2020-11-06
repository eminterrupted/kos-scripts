@lazyGlobal off.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/lib_display.ks").

ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).

from { local x is 5.} until x = 0 step { set x to x - 1.} do {
    print "Test starting in " + x + "..." at (2,2).
    wait 1.
}

local eList is list().

for p in ship:parts {
    if p:hasModule("ModuleTestSubject") {

        disp_test_main(p).
        
        if p:istype("engine") engine_test_throttle_sequence(p).
        else test_part(p).

        wait 10.
    }
}

local function engine_test_throttle_sequence {
    parameter p.

    local t is 60.
    local tStamp is time:seconds + t. 
    local tBuildup is time:seconds + 2.5.
    test_part(p).

    until time:seconds >= tStamp {
        lock throttle to 1 - max(0, min(time:seconds / tBuildup, 1)).
        
        disp_test_main(p).
        disp_engine_perf_data("a").
    }

    deactivate_engine(p).
    clear_disp_block("a").
}