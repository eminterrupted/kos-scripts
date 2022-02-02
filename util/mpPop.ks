clearScreen. 
parameter idx to 0.

local mpPath to path().
//local volList to list().

set mpPath to path(core:volume:name + ":/mp.json").
//if not exists(mpPath) if exists("data_0:/missionPlan.json") set mpPath to path("data_0:/missionPlan.json").

// for vol in volList 
// {
//     if exists(vol:name + ":/missionPlan.json")
//     {
//         set mpPath to path(vol:name + ":/missionPlan.json").
//     }
// }
if mpPath:toString:split("/")[1] <> ""
{
    if exists(mpPath) 
    {
        local mp to readJson(mpPath).
        if mp:length > 0 
        {
            mp:remove(idx).
            mp:remove(idx).
            writeJson(mp, mpPath).
            print "Post-pop plan:".
            print mp.
        }
        else
        {
            print "ERR: " + mpPath + " empty".
        }
    }
    else
    {
        print "ERR: No mission plan found".
    }
}
else 
{
    print "ERR: No mission plan found".
}
