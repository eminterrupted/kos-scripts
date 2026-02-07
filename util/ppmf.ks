// Pretty-print module fields
@lazyGlobal off.
clearscreen. 

parameter params to list().

local m to core. // partmodule
local modname to "". 
local p to ship:parts[0]. // part

if params:length > 0 
{
    if params[0]:IsType("PartModule") 
    {
        set m to params[0].
        set modName to m:Name.
        set p to m:part.
    }
    else if params[0]:IsType("Part")
    {
        set p to params[0].
        if params:length > 1 
        {
            set modname to params[1].
            set m to p:GetModule(modname).
        }
    }
}

local tick to time. 
until terminal:input:haschar 
{
    local tCol to 0.
    local tline to 20.
    print "|= {0,26}          ":Format(modname) at (tcol, tline - 3). 
    print "|  {0,26} : [({1}) {2,-22} ]          ":Format("FieldName", "FieldType", "FieldValue") at (tcol, tline - 2). 
    for fd in m:AllFields 
    {
        local fdparts to fd:remove(0, fd:find(" ") + 1):Split(",").
        local fdname to fdparts[0]:trim.
        local fdtype to fdparts[1]:remove(0, fdParts[1]:FindLast(" ")):trim.
        local fdval  to m:GetField(fdname).
        print "|= [{0,26}] : [({1}) {2,-24} ]    ":Format(fdname, fdtype, fdval) at (tcol, tline). 
        set tline to tline + 1.
    }
    set tick to time.
    print "Tick: {0}     ":Format(tick) at (tcol * 4, tline + 2).
} 
wait until terminal:input:haschar. 
clearscreen. 
