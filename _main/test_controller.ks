@lazyGlobal off.

parameter pList to ship:parts.

//set config:ipu to 500.
clearScreen.
ship:rootPart:getModule("kOSProcessor"):doAction("open terminal",true).
for p in pList {
    if p:tag <> "test" set p:tag to "".
}

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_util.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_engine.ks").
runOncePath("0:/lib/part/lib_light.ks").
runOncePath("0:/lib/lib_contract.ks").

//- start main


//local testParts to list().
check_contracts().
tag_parts_by_title(pList).

local lightList to ship:partsDubbedPattern("lgt").
local pStack to stack().
local uSet to uniqueSet().

for p in pList pStack:push(p).

for p in pStack {
    if p:tag:contains("test") and not uSet:contains(p:name) {
        uSet:add(p:name).
        test_cd(p).
        if p:istype("engine") {
            for e in ship:partsNamed(p:name) test_part(e).
            engine_test_throttle_sequence(p).
        }
        
        else if p:isType("decoupler") {
            for dc in ship:partsNamed(p:name) test_part(dc).
        }
    }
}

wait 2.
if lightList:length > 0 for l in lightList tog_cherry_light(l, false).
clearScreen.

//- end main


local function check_contracts {

    if addons:available("career") {
        local clist to addons:career:activecontracts.
        local tpList to list().

        for contract in clist {
            if contract:title:startsWith("Test") {
                set tplist to parse_contract_param(contract).
            }

            if tpList:length > 0 {
                for p in tplist set p:tag to "test".
            }
        }
    }
}


local function end_eng_test {
    parameter p,
              tEnd.

    if p:flameout return true.
    else if time:seconds >= tEnd return true.
}


local function engine_test_throttle_sequence {
    parameter p.

    local tDur to 15.
    local t to time:seconds.
    local tEnd to t + tDur. 
    local tSpool to 0.

    from { local tval to 1.} until tval <= 0 step { set tval to tval - 0.025.} do {
        lock throttle to max(0, tSpool).
        set tSpool to 1 - max((tval / 1), 0).
        set tDur to time:seconds - t.
        disp_test_main(p, tDur).
        disp_eng_perf_data().
    }

    lock throttle to 1.

    until end_eng_test(p, tEnd) {
        set tDur to time:seconds - t.
        disp_test_main(p, tDur).
        disp_eng_perf_data().
    }

    shutdown_eng(p).
    lock throttle to 0.
    disp_clear_block("eng_perf").
    disp_test_main(p, -2).
}



local function test_cd {
    parameter p.

    if lightList:length > 0 {
        for l in lightList tog_cherry_light(l).
    }

    wait 1.

    from { local x to 5.} until x = 0 step { set x to x - 1.} do {
        disp_test_main(p, -1, x).
        wait 1.
    }
}