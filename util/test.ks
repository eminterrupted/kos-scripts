@lazyGlobal off.
clearscreen.

local tgtList is list(). // Just in case we need it outside of this section
list Targets in tgtList.
for child in Body:OrbitingChildren
{
    tgtList:Add(child).
}

print tgtList.