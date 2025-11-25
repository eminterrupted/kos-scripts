@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").

local errlvl     to 0.

DispMain(ScriptPath(), false).

local appendExisting to false.
local dataRepo  to "0:/test/data/".
local dataSet   to list().
local outPath   to "".
local suffixName to "".

local saveAsJson to false.
local tempScript  to "0:/test/scr/dumpSuffixKey-Temp.ks".

// Param validation
from {local _i to 0.} until _i >= params:length or errLvl > 0 step { set _i to _i + 1. } do
{
    local param to params[_i].
    if _i = 0
    {
        if param:IsType("List") or param:IsType("Lexicon")
        {
            set dataSet to param.
            OutMsg("dataSet confirmed  ").
            OutMsg("length: {0}  ":format(dataSet:Length)).
        }
        else
        {
            set errLvl to 7.
        }
    }
    else
    {
        if param:IsType("String")
        {
            if param:MatchesPattern("Append")
            {
                set appendExisting to true.
            }
            else
            {
                local paramSplit to param:Split(".").
                if paramSplit:Length > 1
                {
                    set outPath to param.
                    set saveAsJson to paramSplit[paramSplit:Length - 1] = "json".
                    OutInfo("outPath set  ").
                    OutInfo("[{0}]  ":Format(outPath), 1).
                }
                else
                {
                    set suffixName to param.
                    OutInfo("suffixName set   ").
                    OutInfo("[{0}]   ":Format(suffixName), 1).
                }
            }
        }
    }
}

if suffixName:Length = 0
{
    set errLvl to 2.
}
else if outPath:Length = 0
{
    set errLvl to 3.
}
else if outPath:Split("."):Length = 1
{
    set errLvl to 4.
}
else
{
    if not outPath:Contains(":")
    {
        set outPath to choose dataRepo + outPath:substring(1,outPath:Length - 1) if outPath:StartsWith("/") else dataRepo + outPath.
    }
    if not exists(Path(outPath):Parent)
    {
        createDir(Path(outPath):Parent).
    }
    else if exists(Path(outPath)) and not appendExisting
    {
        OutInfo("Removing priot output file").    
        DeletePath(outPath).
        wait 0.1.
    }
    OutInfo("Final output path: {0}":Format(outPath)).
    OutInfo("",1).
    wait 0.1.
}


if errLvl = 0
{
    if exists(tempScript)
    {
        deletePath(tempScript).
    }

    OutInfo("Writing temp script").

    log "parameter _ds." to tempScript.
    if saveAsJson
    {
        log "local tempJson to list()." to tempScript.
        log "from {local i to 0.} until i >= _ds[0]:length step {set i to i + 1.} do {" to tempScript.
        log "  set _d to _ds[0][i]." to tempScript. 
        log "  tempJson:Add(list(_d:name, _d:{0})).":Format(suffixName) to tempScript.
        log "}" to tempScript.
        log "writeJson(tempJson, '{0}').":Format(outPath):Replace("'", char(34)) to tempScript.
    }
    else
    {
        log "for _d in _ds[0] {" to tempScript. 
        local tmpStr to "  log '~~~0???,~~~1???':Format(_d:name, _d:{0}) to '{1}'.":Format(suffixName, outPath).
        log tmpStr:Replace("~~~", "{"):Replace("???", "}"):Replace("'", char(34)) to tempScript.
        log "}" to tempScript.
    }
    OutInfo("Running temp script").
    runPath(tempScript, list(dataSet)).

    if not exists(outPath)
    {
        set errLvl to 1.
    }
    else
    {
        OutInfo("Run complete, cleaning up script").
        deletePath(tempScript).
    }
}

clearScreen.

if errLvl = 0
{
    OutInfo("script complete!").
}
else if errLvl = 1
{
    OutInfo("Error: output file was not generated.").
    OutInfo(" Check if your filename is valid and there is sufficient space ", 1).
}
else if errLvl = 2
{
    OutInfo("Error: No suffixName provided.").
    OutInfo(" A valid suffixname must be provided ", 1).
}
else if errLvl = 3
{
    OutInfo("Error: No outputFileName provided.").
    OutInfo(" must either be filename.ext or full path including volume", 1).
}
else if errLvl = 4
{
    OutInfo("Error: No outputFileName extension provided.").
    OutInfo(" must either be filename.ext or full path including volume", 1).
}
else if errLvl = 7
{
    OutInfo("Error: First token is not an accepted type (List or Lexicon)").
    OutInfo("Value: [{0}]   TypeName: [{1}] ":Format(params[0], params[0]:TypeName), 1).
}