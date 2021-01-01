//Library to automatically tag parts by categories defined in json file.
@lazyGlobal off.

parameter mode to "".

runOncePath("0:/lib/lib_init").
global tagRef to tag_init_ref().

if mode = "" {
    tag_parts_by_title(ship:parts).
}
else if mode = "tag" tag_parts_by_title(ship:parts).
else if mode = "clr" tag_clear().

//-- main functions
global function get_stg_id_from_tag {
    parameter p.

    local tagList to p:tag:split(".").
    for t in tagList {
        if t:startsWith("stgId") {
            return t:split(":")[1].
        }
    }

    return "".
}




local function tag_init_ref {
    local nRefFile to "0:/data/name_ref.json".
    local n to choose readJson(nRefFile) if exists(nRefFile) else lex().

    local ntRefFile to "0:/data/name_tag_ref.json".
    local nt to choose readJson(ntRefFile) if exists(ntRefFile) else lex().

    local tRefFile to "0:/data/tag_ref.json".
    local t to choose readJson(tRefFile) if exists(tRefFile) else lex().

    return lexicon( "n", n, "nt", nt, "t", t, "file", lex( "n", nRefFile, "nt", ntRefFile, "t", tRefFile)).
}


global function tag_clear {
    parameter inList to ship:parts.

    local func to "[tag_clear_tags] ".

    for p in inList {
        set p:tag to "".
    }
}

global function tag_parts_by_title {
    
    parameter inList.
    local func to "[tag_parts_by_title] ".


    global idxObj to lex().

    for p in inList {
        if tagRef["t"]:hasKey(p:title) {
            local preTag to p:tag:split(".").
            local refTag to tagRef["t"][p:title].
            local tagList to refTag:split(".").
            
            if preTag[0] <> tagList[0] {
                set tagList to tag_meta_type(p, refTag).
                
                for t in preTag {
                    if t <> "" tagList:add(t).
                }
        
                set p:tag to tagList:join(".").
                local pName to p:name:replace(" (" + ship:name + ")","").
                if not tagRef["nt"]:hasKey(pName) set tagRef["nt"][pName] to tagRef["t"][p:title].
            }
        }

        else {
            set errLvl to 1.
            if not (tagRef["t"]:hasKey(p:title)) set tagRef["t"][p:title] to "".
            set errObj[p:title] to "NoRef".
        }

        clearScreen.

        if not (tagRef["n"]:hasKey(p:title)) set tagRef["n"][p:title] to p:name:replace(" (" + ship:name + ")", "").
    }

    tag_light_meta().

    writeJson(tagRef["t"], tagRef["file"]["t"]).
    writeJson(tagRef["nt"], tagRef["file"]["nt"]).
    writeJson(tagRef["n"], tagRef["file"]["n"]).
    return true.
}


// local functions
local function tag_bay_core_id {
    parameter p.

    local id to 0.
    local par to p:parent.

    if par:tag:matchesPattern("bay.doors.*.bayid:\d") {
        set id to par:tag:split(".")[1].
    }
    
    else if true {
        for c in p:children {
            if c:tag:matchesPattern("bay.doors.*.bayid:\d") {
                set id to c:tag:split(".")[1].
            }
        }
    }

    else {
        if not idxObj:hasKey("bayIdx") set idxObj["bayIdx"] to 0.
        set id to idxObj["bayIdx"].
    }

    return "bayid:" + id.
}


local function tag_bay_door_id {
    parameter p.

    local chld to p:children.
    local id to 0.
    local par to p:parent.
    local pTag to "".

    if par:tag:matchespattern("bay.core.*.bayid:\d") {
        set pTag to par:tag.
        set id to pTag:substring(pTag:find("bayid") + 6, 1).
    }

    else if true {
        for c in chld {
            if c:tag:matchesPattern("bay.core.*.bayid:\d") {
                local cTag to c:tag.
                set id to cTag:substring(cTag:find("bayid") + 6, 1).
            }
        }
    }

    else {
        if not idxObj:hasKey("bayIdx") set idxObj["bayIdx"] to 0.
        set id to idxObj["bayIdx"].
    }

    return "bayid:" + id.
}


local function tag_bay_meta {
    parameter p.

    local meta to tag_stage_meta(p).
    local refTag to tagRef["t"][p:title].

    if refTag:matchespattern("bay.doors") set meta to meta + "." + tag_bay_door_id(p).
    else if refTag:matchespattern("bay.core") set meta to meta + "." + tag_bay_core_id(p).

    return meta. 
}


local function tag_cap_meta {
    parameter p.

    local meta to tag_stage_meta(p).
    
    if not idxObj:hasKey("capIdx") set idxObj["capIdx"] to 0.
    local id to idxObj["capIdx"].

    set meta to meta + ".capId:" + id.
    set idxObj["capIdx"] to id + 1.

    return meta.
}


local function tag_cmd_ctrl_meta {
    parameter p.

    local meta to "".
    set meta to choose "" if p:tag:matchesPattern(".stgId:-??\d") else tag_stage_meta(p). 
    if p:hasModule("kOSProcessor") set meta to meta + tag_cpu_meta(p).

    return meta.
}


local function tag_cpu_meta {
    parameter p.

    local m to p:getModule("kOSProcessor").
    local meta to "".
    local vName to m:volume:name.
    if vName = "local" set meta to meta + ".cpuid:" + 1.
    if vName = "log" set meta to meta + ".cpuid:" + 2.
    else if vName:startsWith("data_") set meta to meta + ".cpuid:" + vName:replace("data_","").

    return meta.
}


local function tag_dc_meta {
    parameter p.
    
    return tag_stage_meta(p).
}


local function tag_eng_meta {
    parameter p.

    local meta to "".
    local stg to p:decoupledIn.
    local stgMeta to tag_stage_meta(p).

    if not idxObj:hasKey(stg) set idxObj[stg] to lex("engIdx",0).
    else if not idxObj[stg]:hasKey("engIdx") set idxObj[stg]:engIdx to 0.
    local id to idxObj[stg]:engIdx.
    
    set meta to stgMeta + ".id:" + id.
    set idxObj[stg]:engIdx to id + 1.
    return meta.
}


local function tag_light_meta {
    
    local id to 0.
    local meta to "".
    
    for p in ship:partsTaggedPattern("lgt") {
        local stg to tag_stage_meta(p).
        local tagList to tagRef["t"][p:title]:split(".").

        if not idxObj:hasKey(stg) set idxObj[stg] to lex("lgtIdx",0).
        else if not idxObj[stg]:hasKey("lgtIdx") set idxObj[stg]:lgtIdx to 0.
        set id to idxObj[stg]:lgtIdx. 
        
        if p:parent:tag:matchesPattern("bay.*.bayid:\d") {
            local bayId to p:parent:tag:substring(p:parent:tag:find("bayId"), 7).
            set bayId to bayId:split(":")[1].
            set meta to stg +  ".bayid:" + bayId.
        }

        else set meta to stg + ".id:" + id.

        for t in meta:split(".") {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }

        set p:tag to tagList:join(".").
        set idxObj[stg]:lgtIdx to id + 1.
    }
}


local function tag_meta_type {
    parameter p,
              tag.

    local meta to choose tag_stage_meta(p) if not tag:matchesPattern("s:-??\d") else "".
    local tagList to tag:split(".").

    if tagList[0] = "cmd" or (tag:contains("test") and p:hasModule("kOSProcessor")) {
        set meta to tag_cmd_ctrl_meta(p):split(".").
        for t in meta {
            if t <> "" tagList:insert(tagList:length, t).
        }
    }

    else if tagList[0] = "ctrl" {
        set meta to tag_cmd_ctrl_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }
    
    else if tagList[0] = "eng" {
        set meta to tag_eng_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }

    else if tagList[0] = "tank" {
        set meta to tag_tank_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }

    else if tagList[0] = "bay" {
        set meta to tag_bay_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }

    else if tagList[0] = "cap" {
        set meta to tag_cap_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }
    
    else if tagList[0] = "dc" {
        set meta to tag_dc_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }

    else {
        set meta to tag_stage_meta(p):split(".").
        for t in meta {
            if t <> "" {
                tagList:insert(tagList:length, t).
            }
        }
    }
    
    return tagList.
}


local function tag_stage_meta {
    parameter p.

    if p:tag:matchesPattern(".stgId:-??\d") {
        return "".
    } else {
        if p:typeName <> "Decoupler" {
            return ".stgId:" + p:decoupledIn.
        } else {
            return ".stgId:" + p:stage.
        }
    }
}


local function tag_tank_meta {
    
    parameter p.

    local func to "[tag_get_tank_meta] ".
    local meta to "".
    local res to p:resources.
    local stg to p:decoupledIn.
    local stgMeta to tag_stage_meta(p).

    if res:length > 0 {
        for r in res {
            if r:name = "LiquidFuel" set meta to meta + "lf".
            else if r:name = "LiquidHydrogen" set meta to "lh2".
            else if r:name = "LqdHydrogen" set meta to "lh2".
            else if r:name = "Oxidizer" set meta to meta + "o".
            else if r:name = "MonoPropellant" set meta to meta + "mono".
            else if r:name = "SolidFuel" set meta to meta + "solid".
            else if r:name = "XenonGas" set meta to meta + "xe".
            else if r:name = "ArgonGas" set meta to meta + "ar".
            else if r:name = "Snacks" set meta to meta + "snacks".
            else if r:name = "Ore" set meta to meta + "ore".
            else if r:name = "Hydrogen" set meta to meta + "h".
            else if r:name = "Water" set meta to meta + "h2o".
            else if r:name = "Oxygen" set meta to meta + "o2".
            else if r:name = "Soil" {
                set errLvl to 1. 
                print func + "Ignoring resource type: " + r:name.
            }
            else {
                set errLvl to 1.
                set meta to meta + "unk".
                print func + "Unknown resource type: " + r:name.
            }
        }
    }

    if not idxObj:hasKey(stg) set idxObj[stg] to lex("tankIdx",0).
    else if not idxObj[stg]:hasKey("tankIdx") set idxObj[stg]:tankIdx to 0.
    local id to idxObj[stg]:tankIdx.

    set meta to meta + stgMeta + ".tankid:" + id.
    set idxObj[stg]:tankIdx to id + 1.

    return meta.
}