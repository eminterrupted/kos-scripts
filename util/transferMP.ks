@lazyGlobal off.
clearScreen.

parameter fromCore,
          toCore,
          transferControl to true.

runOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

local fromVol to fromCore:volume:name.
local toVol to toCore:volume:name.
local transferSafe to false.

OutMsg("Copying mission plan from {0} to {1}":format(fromVol, toVol)).
if exists(Path(fromVol + ":/mp.json"))
{
    copyPath(Path(fromVol + ":/mp.json"), Path(toVol + ":/mp.json")).
    if exists(Path(toVol + ":/mp.json"))
    {
        deletePath(fromVol + ":/mp.json").
        set transferSafe to true.
        OutInfo(" [X] mp.json").
    }
    else
    {
        OutInfo("[ ] mp.json (Not on destination!)").
    }
}
else
{
    OutInfo("[ ] mp.json (No Source!)").
}

if exists(Path(fromVol + ":/mp"))
{
    copyPath(Path(fromVol +":/mp"), Path(toVol + ":/mp")).
    if exists(Path(toVol + ":/mp"))
    {
        set transferSafe to true.
        OutInfo2("[X] mp <folder>").
    }
    else
    {
        OutInfo2("[ ] mp <folder> (Not on destination!)").
    }
}
else
{
    OutInfo2("[ ] mp <folder> (Not on Source!)").
}

if transferControl and transferSafe
{
    copyPath(Path("0:/boot/_bl"), Path(toVol + ":/boot/_bl.ks")).
    set fromCore:bootFileName to "".
    set toCore:bootFileName to "/boot/_bl.ks".

    deletePath(Path(fromVol + ":/mp.json")).
    deletePath(Path(fromVol + ":/mp")).
    deletePath(Path(fromVol + ":/boot")).
    local mpVal to readJson(Path(toVol + ":/mp.json")).
    if mpVal[0] = "util/transferMP" 
    {
        mpVal:remove(1).
        mpVal:remove(0).
        writeJson(mpVal, Path(toVol +":/mp.json")).
        
        copyPath(Path(fromVol + ":/vessel.json"), Path(toVol + ":/vessel.json")).
        deletePath(Path(fromVol + ":/vessel.json")).
    }
    
    local tagPkg to toCore:tag:split("_").
    set toCore:tag to fromCore:tag.
    set fromCore:tag to "{0}_{1}":format(fromCore:part:uid, tagPkg[1]).
    OutTee("MP Transfer completed!").
    if toCore:part:hasSuffix("ControlFrom") set toCore:part:controlFrom to true.
}
else
{
    OutTee("MP Transfer not completed!").
}
wait 1.
OutInfo().
OutInfo2().