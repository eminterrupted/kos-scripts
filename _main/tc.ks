@lazyGlobal off.

parameter pList to ship:parts.

//set config:ipu to 500.
clearScreen.
core:doAction("open terminal",true).
for p in pList {
    if p:tag <> "test" set p:tag to "".
}

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_tag").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_engine").
runOncePath("0:/lib/part/lib_light").
runOncePath("0:/lib/lib_contract").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_part_test").

//- start main



//local testParts to list().
check_contracts().
tag_parts_by_title(pList).

local lightList to ship:partsDubbedPattern("lgt").
local pStack to stack().
local uSet to uniqueSet().

for p in pList pStack:push(p).

if lightList:length > 0 {
    for l in lightList tog_cherry_light(l).
}

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

        else {
            for tpart in ship:partsNamed(p:name) test_part(tpart).
        }
    }
}

test_sci_list().

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
                print contract:title.
                set tplist to parse_contract_param(contract).
            }

            if tpList:length > 0 {
                for p in tplist {
                    set p:tag to "test".
                    print p at (2, 144).
                }
            }
        }
    }
}


local function end_eng_test {
    parameter p,
              tEnd.

    local solid is false.
    for res in p:resources {
        if res:name = "SolidFuel" set solid to true. 
    }

    if solid {
        until p:flameout {
            return false.
        } 

        return true.
    }
    
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


local function test_sci_list {
    local sciList to get_sci_mod_for_parts(ship:parts).



    if sciList:length > 0 {
        from { local x is 0. } until x = sciList:length step { set x to x + 1. } do {
            disp_test_main(sciList[x]:part, -1, x).
            sciList[x]:deploy().
            wait until sciList[x]:hasData.
            wait 1.
        }
    }
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