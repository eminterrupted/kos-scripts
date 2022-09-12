@lazyGlobal off. 

clearScreen.

local lp to ship:partsDubbedPattern("ClampBase")[0].
local i to 0.
clearScreen.
print "Idk, something" at (2, 2).
local curLine to 4.
local _str to " ".
until false 
{
    local m to lp:getModuleByIndex(i).
    if m:allFields:length > 1 
    {
        set _str to m:allFields:join("][").
    } 
    else if m:allFields:length > 0
    {
        set _str to m:allFields[0]. 
    }
    else
    {
        set _str to " ".
    }
    
    print "[" + _str + "]" at (2, 25).
    print "{0, 40}  -  {1,-30}":format(m:name, _str) at (0, curLine).
    set i to i +1.
    set curLine to curLine + 1.
    if i = lp:allModules:length break.
}
