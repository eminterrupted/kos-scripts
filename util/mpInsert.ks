parameter planToPush, popFirst is true.

local mpPath to path().

set mpPath to path(core:volume:name + ":/missionPlan.json").

if mpPath:toString:split("/")[1] <> ""
{
    if exists(mpPath) 
    {
        local mp to readJson(mpPath).
        local mpList to list(planToPush).

        if popFirst mp:pop().

        local mpCopy to mp:copy.
        if mpCopy:length > 0 
        {
            from { local i to 0.} until i >= mpCopy:length step { set i to i + 1.} do
            {
                mpList:add(mpCopy:pop()).
            }

            // for p in mpCopy
            // {
            //     mpList:add(mpCopy:pop()).
            // }
            
            local mpQueue to queue().
            for p in mpList 
            {
                mpQueue:push(p).
            }
            
            writeJson(mpQueue, mpPath).
            print "Post-op plan:".
            print mpQueue.
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
