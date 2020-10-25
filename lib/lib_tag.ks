//Library to automatically tag parts by categories defined in json file.
@lazyGlobal off.

parameter mode is "".

runOncePath("0:/lib/lib_init.ks").

init_err().

if mode = "" logStr("[lib_tag.ks] Loading library").
else if mode = "tag" tag_parts_by_title(ship:parts).
else if mode = "clear" clear_tags(ship:parts).
else if mode = "dump" dump_ship_tags().

uplink_telemetry().

//-- main functions

global function clear_tags {
    parameter inList.

    local func is "[clear_tags] ".

    logStr(func + "Clearing tags").
    for p in inList {
        set p:tag to "".
        logStr(func + "Tag cleared for part: [" + p:cid + ", " + p:name + "]").
    }
}


global function tag_parts_by_title {
    
    parameter inList.

    local refFile is "0:/data/tag_ref.txt".
    local refObj is lexicon().
    local func is "[tag_parts_by_title] ".

    init_err().
    if exists(refFile) set refObj to readJson(refFile). 

    for p in inList {
        if refObj:hasKey(p:title) {
            
            local metaStr is "".
            local postTag is "".
            local preTag is p:tag. 
            local pTitle is p:title.
            local refTag is refObj[pTitle].

            if not (preTag = "") set postTag to "." + p:tag.

            if not (preTag:contains(refTag)) {
                if refTag:startsWith("tank") set metaStr to get_tank_meta(p).

                if metaStr <> "" set postTag to postTag + metaStr.
                set p:tag to refTag + postTag.

                logStr(func + "Part tag updated [" + p:cid + ", " + p:name + ", " + preTag + " -> " + p:tag + "]").
            }

            else {
                set errLvl to 1.
                logStr(func + "Part already tagged [" + p:cid + ", " + p:name + ", " + p:tag + "]", errLvl).
            }
        }

        else {
            set errLvl to 1.
            logStr(func + "Part missing reference tag: [(" + p:name + ")]").
            if not (refObj:hasKey(p:title)) set refObj[p:title] to "".
            set errObj[p:title] to "NoRef".
        }
    }

    if ship:partsTaggedPattern("bay.doors"):length > 0 {
        set_bay_ids(ship:partsTaggedPattern("bay.doors")).
    }

    if ship:partsTaggedPattern("power.cap"):length > 0 {
        set_cap_ids(ship:partsTaggedPattern("power.cap")).
    }

    logStr(func + "Tagging completed, writing updates to tag_ref").

    writeJson(refObj,refFile).

    return true.
}


//-- Local functions
local function dump_ship_tags {

    local func is "[dump_ship_tags] ".
    local pList is ship:parts.
    local refObj is lexicon().
    local dumpPath is "0:/data/tag_dump_" + ship:name + ".txt".

    logStr(func + "Dumping part tags for vessel to " + dumpPath).

    for p in pList {
        set refObj[p:title] to p:tag.
    }

    print refObj.
    writeJson(refObj, dumpPath).
}


local function get_tank_meta {
    
    parameter part.

    local func is "[get_meta_for_part] ".
    local meta is ".".
    local res is list().

    set res to part:resources.
    if res:length > 0 {
        for r in res {
            if r:name = "LiquidFuel" set meta to meta + "lf".
            else if r:name = "LiquidHydrogen" set meta to "lh2".
            else if r:name = "Oxidizer" set meta to meta + "o".
            else if r:name = "MonoPropellant" set meta to meta + "mono".
            else if r:name = "XenonGas" set meta to meta + "xe".
            else if r:name = "ArgonGas" set meta to meta + "ar".
            else if r:name = "Snacks" set meta to meta + "snacks".
            else if r:name = "Ore" set meta to meta + "ore".
            else if r:name = "Hydrogen" set meta to meta + "h".
            else if r:name = "Water" set meta to meta + "h2o".
            else if r:name = "Oxygen" set meta to meta + "o2".
            else if r:name = "Soil" {
                set errLvl to 1. 
                logStr(func + "Ignoring resource type: " + r:name, errLvl).
            }
            else {
                set errLvl to 1.
                set meta to meta + "unk".
                logStr(func + "Unknown part resource: " + r:name, errLvl).
            }
        }
    }
    
    else {
        set errLvl to 1.
        logStr(func + "Part was tagged as (" + part:tag + ") but no resources were found", errLvl).

    }
    
    return meta.
}


local function set_bay_ids {
    
    parameter bayList is ship:partsTaggedPattern("bay.doors").

    local func is "[set_bay_ids] ".
    local bayCount is 0.

    if bayList:length > 0 {
    
        for b in bayList {
            if b:tag:contains(".us") and not (b:tag:contains(".bayId.")) {
                logStr(func + "Untagged UniversalStorage bay module found: [" + b:cid + ", " + b:name + ", " + b:tag + "]").
                set b:tag to b:tag + ".bayId." + bayCount.
                set_us_bay_core_id(b, bayCount).
                set_bay_light_id(b, bayCount).

                set bayCount to bayCount + 1.
            }

            else if b:hasModule("ModuleAnimateGeneric") and not (b:tag:contains(".bayId.")) {
                logStr(func + "Untagged stock bay module found: [" + b:cid + ", " + b:name + ", " + b:tag + "]").
                set b:tag to b:tag + ".bayId." + bayCount.
                set_bay_light_id(b, bayCount).

                set bayCount to bayCount + 1.
            }
        }
    }

    else {
        set errLvl to 1.
        logStr(func + "No bay doors found in bayList param", errLvl). 
    }
}


local function set_us_bay_core_id {
    
    parameter bay,
              bayCount.

    local func is "[set_us_bay_core_id] ".

    logStr(func + "Checking parent part for untagged US bay core: [" + bay:parent:cid + ", " + bay:parent:title + ", " + bay:parent:tag + "]").

    if bay:parent:tag:contains("bay.core") and not (bay:parent:tag:contains("bayId")) {
        logStr(func + "Untagged bay.core found: [" + bay:parent:cid + ", " + bay:parent:title + ", " + bay:parent:tag + "]").
        set bay:parent:tag to bay:parent:tag + ".bayId." + bayCount.
    }

    else {
        for b in bay:children {
            logStr(func + "Checking child part for untagged US bay core: [" + b:cid + ", " + b:title + ", " + b:tag + "]").
            if b:tag:contains("bay.core") and not (b:tag:contains("bayId")) {
                logStr(func + "Untagged bay.core found: [" + b:cid + ", " + b:title + ", " + b:tag + "]").
                set b:tag to b:tag + ".bayId." + bayCount.
            }
        }
    }
}


local function set_bay_light_id {

    parameter   bay,
                bayCount.

    local func is "[set_bay_light_id] ".

    local bChildren is bay:children.
    local bParent is bay:parent.
    local pChildren is bParent:children.

    for c in bChildren {
        logStr(func + "Checking bay child part for attached light module(s): [" + c:cid + ", " + c:title + ", " + c:tag + "]").
        if c:tag:contains("light") {
            logStr(func + "Light module(s) found: [" + c:cid + ", " + c:title + ", " + c:tag + "]").
            set c:tag to c:tag + ".bayId." + bayCount.
        }
    }

    if bParent:tag:contains("core") {
        logStr(func + "Checking bay core for attached light modules(s): [" + bParent:cid + ", " + bParent:title + ", " + bParent:tag + "]").
        for c in pChildren {
            if c:tag:contains("light") {
                logStr(func + "Light module(s) found: [" + c:cid + ", " + c:title + ", " + c:tag + "]").
                set c:tag to c:tag + ".bayId." + bayCount.
            }
        }
    }
}


local function set_cap_ids {
    
    parameter capList is ship:partsTaggedPattern("power.capacitor").

    local func is "[set_cap_ids] ".
    local capCount is 0.

    if capList:length > 0 {
    
        for c in capList {
            logStr(func + "Untagged capacitor found: [" + c:cid + ", " + c:name + ", " + c:tag + "]").
            set c:tag to c:tag + ".capId." + capCount.
            set capCount to capCount + 1.
        }
    }

    else {
        set errLvl to 1.
        logStr(func + "No capacitors found in capList param", errLvl).
    }
}