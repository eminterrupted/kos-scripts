// #include "0:/boot/_bl"
ParseMissionTags(core).

// Bootloader functions
global function TagCores
{
    local idx to 2.
    for c in ship:modulesNamed("kOSProcessor")
    {
        if c:volume:exists("mp.json") or c:volume:exists("mp")
        {
            set c:volume:name to "{0}_MP1":format(core:part:uid).
        }
        else if c:tag = "" 
        {
            set c:tag to "{0}:CX{1}":format(c:part:uid, idx).
            set c:volume:name to "{0}_VX{1}":format(c:part:uid, idx).
            set idx to idx + 1.
        }
        else if c:volume:name = ""
        {
            set c:volume:name to "{0}_VX{1}":format(c:part:uid, idx).
            set idx to idx + 1.
        }
    }
}


// global function TagCores
// {
//     set core:volume:name to "PLX0".
    
//     local idx to 1.
//     for c in ship:modulesNamed("kOSProcessor")
//     {
//         if c:tag = "" 
//         {
//             set c:tag to "PCX" + idx.
//             set c:volume:name to "PLX" + idx.
//             set idx to idx + 1.
//         }
//         else if c:volume:name = ""
//         {
//             set c:volume:name to "PLX" + idx.
//             set idx to idx + 1.
//         }
//     }
// }

global function CopyArchivePlan
{
    parameter archivePlan,
              localPlan is "1:/mp.json".

    if exists(archivePlan)
    {
        copyPath(archivePlan, localPlan).
    }
}

global function ParseTags
{
    parameter _t is core:tag.

    // Sample of _t value: "csat:ctag[duna;28355;21514;17;324.6;181.4]|0"
    
    if not (defined paramLex) global paramLex to lex().
    local  fragmentList to list().

    local pipeSplit to _t:split("|").
    local colonSplit to pipeSplit[0]:split(":").

    for fragment in colonSplit
    {
        if fragment:matchespattern("\[.*\]")
        {
            local isoFrag to fragment:substring(0, fragment:find("[")).
            fragmentList:add(isoFrag).
            local isoPrm to fragment:replace(isoFrag + "[", ""):replace("]", "").
            set paramLex[isoFrag] to isoPrm:split(";").
        }
        else
        {
            fragmentList:add(fragment).
        }
    }
    return list(fragmentList, pipeSplit[1]).
}

global function ParseMissionTags
{
    parameter c is core.

    return ParseTags(c:tag)[0].
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