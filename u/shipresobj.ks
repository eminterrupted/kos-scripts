@lazyGlobal off.

runOncePath("0:/lib/lib_tag").

clearscreen.

local resLex is lex().
local resIdx is 0.
local stgId to 0.

for r in ship:resources {
    local rParts to r:parts.
    for p in rParts {
        local tagList to p:tag:split(".").
        set stgId to get_stg_id_from_tag(p).
    }

    for pRes in p:resources {
        if r:name = pRes:name {

            //Tally resources by stgId in 
            if resLex:haskey(stgId) {
                if resLex[stgId]:hasKey(r:name)


                if resLex[stgId]:hasKey(r:name)
                print "".
            }
        }
    }
}