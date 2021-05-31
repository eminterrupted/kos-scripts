local mpPath to path().
local volList to list().
list volumes in volList.
for vol in volList 
{
    if exists(vol:name + ":/missionPlan.json")
    {
        set mpPath to path(vol:name + ":/missionPlan.json").
    }
}
if mpPath:toString:split("/")[1] <> ""
{
    if exists(mpPath) 
    {
        local mp to readJson(mpPath).
        if mp:length > 0 
        {
            mp:pop().
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
