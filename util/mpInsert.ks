parameter valToPush, 
          idx is 0, 
          popFirst is false.

local mpPath to path().

set mpPath to path(core:volume:name + ":/mp.json").

if mpPath:toString:split("/")[1] <> ""
{
    if exists(mpPath) 
    {
        local mp to readJson(mpPath).
        
        if popFirst runPath("0:/util/mpPop", idx).
                
        mp:insert(0, valToPush[1]).
        mp:insert(0, valToPush[0]).

        writeJson(mp, mpPath).
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
