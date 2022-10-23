@lazyGlobal off.
clearScreen.

parameter _params to list().

runOncePath("0:/lib/loadDep").

DispMain(ScriptPath(), false).

local _doneFlag to false.
local _mode to "read".
local _mp to "mp.json".

if _params:length > 0 
{
    set _mode to _params[0].
    if _params:length > 1 set _mp to _params[1].
}

if _mode = "read"
{
    print _mp at (2, g_line).

    if _mp:isType("string") 
    {
        print "Converting from string" at (2, cr()).
        set _mp to Path(_mp).
    }

    if exists(_mp)
    {
        print "Plan found!" at (2, cr()).
        DispMissionPlan(readJson(_mp)).
    }
    else
    {
        print "Plan not found!" at (2, cr()).
        OutMsg("ERROR: No mission plan found!").
    }
}
else if _mode = "append"
{
    until _doneFlag
    {
        set _mp to PlanBuilderNextScript(_mp).
    }
}
else if _mode = "build"
{
    set _mp to list().
    local aRoot to volume("archive"):files["main"].
    Breakpoint().
    local repo to PlanBuilderInit(aRoot).
    DispPathTree(repo).
    Breakpoint().


    until _doneFlag
    {
        set _mp to PlanBuilderNextScript(_mp).
    }
}



local function PlanBuilderInit
{
    parameter _scrDir.

    local scriptRepo to lex(_scrDir:name, list()).
    
    for item in _scrDir:lexicon:values
    {
        scriptRepo["root"]:add(item).
    }

    return scriptRepo.
}


local function PlanBuilderNextScript
{
    parameter _plan.

    
}


local function DispPathTree
{
    parameter _root,
              _line is g_line.

    set g_line to _line.

    local _col to 0. 
    local _colSize to 4.
    local _curPath to "<({0})>:":format(_root).
    local _str to "({0}) CONTENTS":format(_root).
    local _strIter to _str:iterator.
    _strIter:next.

    print _str at (0, g_line).
    cr().
    until _strIter:atend
    {
        print "-" at (_strIter:index, g_line).
    }
    cr().

    local prtStr to "{0,-50}  [{1,-4}]  {2}".
    print prtStr:format("FILE", "TYPE", "SIZE") at (0, cr()).

    // Dir pass
    for _i in _root
    {
        set _curPath to "{0}/{1}":format(_curPath, _i:name:toUpper).
        local prtStr to "{0,-50}  [{1,-4}]  {2}".
        
        if _i:isFile
        {
            //print prtStr:format(_curPath, "File", _i:size) at (_col * _colSize, cr()).
        }
        else
        {
            print prtStr:format(_curPath, "Dir", _i:size) at (_col * _colSize, cr()).
            
        }
    }
}