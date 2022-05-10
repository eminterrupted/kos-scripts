// #include "0:/boot/_bl_mini"
ParseMissionTags(core).

// Bootloader functions
global function TagCores
{
    set core:volume:name to "PLX0".
    
    local idx to 1.
    for c in ship:modulesNamed("kOSProcessor")
    {
        if c:tag = "" 
        {
            set c:tag to "PCX" + idx.
            set c:volume:name to "PLX" + idx.
            set idx to idx + 1.
        }
        else if c:volume:name = ""
        {
            set c:volume:name to "PLX" + idx.
            set idx to idx + 1.
        }
    }
}

global function CopyArchivePlan
{
    parameter archivePlan,
              localPlan is "1:/mp.json".

    if exists(archivePlan)
    {
        copyPath(archivePlan, localPlan).
    }
}

global function ParseMissionTags
{
    parameter c.

    local fragmentList to list().
    local pipeSplit to c:tag:split("|").
    for word in pipeSplit
    {
        local colonSplit to word:split(":").
        for frag in colonSplit
        {
            fragmentList:add(frag).
        }
    }
    return fragmentList.
}


// Parses mission plans that are saved in CSV format
global function CSVtoObj
{
    parameter csv. // formatted mission csv file

    local mpObj to list().
    for f in open(csv):ReadAll 
    {
        local mission to f:split(";").
        local scr to mission[0].
        mpObj:add(scr).
        local params to mission[1].
        mpObj:add(params).
    }
    return mpObj.
}