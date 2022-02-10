clearScreen. 

parameter valToPush, 
          idx is 0, 
          popFirst is false.

local mpPath to path().

set mpPath to path(core:volume:name + ":/mp.json").

if mpPath:toString:split("/")[1] <> ""
{
    if exists(mpPath) 
    {
        if popFirst runPath("0:/util/mpPop", idx).
     
        local mp to readJson(mpPath).
        
        mp:insert(idx, valToPush[1]).
        mp:insert(idx, valToPush[0]).

        writeJson(mp, mpPath).
        print "Post-insert plan:".
        print mp.
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
