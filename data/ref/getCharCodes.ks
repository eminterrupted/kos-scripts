@LazyGlobal off.
ClearScreen.

parameter _params is list().

local fileDate to Time.

local _outFile to "".
local _rangeMin to 0.
local _rangeMax to 16384.
local _writeMode to 1. // 0="New_Overwrite"; 1="New_NoCollision";2="NewOrEdit";3="NewOrBypass"
local _onlyPosiLenChars to false.
local _quoteColumns to false.
local _quoteChar to "'".

if _params:Length > 0
{
    set _outFile to _params[0].
    if _params:Length > 1 set _rangeMin to _params[1].
    if _params:Length > 2 set _rangeMax to _params[2].
    if _params:Length > 3 set _writeMode to _params[3].
    if _params:Length > 4 set _onlyPosiLenChars to _params[4].
    if _params:Length > 5 set _quoteColumns to _params[5].
    if _params:Length > 6 set _quoteChar to _params[6].
}

print "Unicode Generator".
print "-----------------".
print " ".
print "Starting operation:".
print " - Range Min: {0} ":Format(_rangeMin).
print " - Range Max: {0} ":Format(_rangeMax).
print " - Posichars: {0} ":Format(_onlyPosiLenChars).
print " ".

local bypassFlag to false.
local overwriteFlag to false.

if _outFile:Length = 0
{
    set _outFile to "0:/data/ref/unicodeCharCodes_{0,6:0}-{1,6:0}":Format(_rangeMin, _rangeMax).
    set _outFile to _outFile + "_{0}.csv".
    from { local i to 0. local _doneFlag to false. } until _doneFlag step { set i to i + 1.} do
    {
        local testOut to _outFile:Format(i).
        if exists(testOut)
        {
            if _writeMode = 3
            {
                set _doneFlag to true.
                set bypassFlag to true.
            }
            else if _writeMode = 2
            {
                set _outFile to testOut.
                set _doneFlag to true.
                set overwriteFlag to false.
            }
            else if _writeMode = 0
            {
                set _outFile to testOut.
                set _doneFlag to true.
                set overwriteFlag to true.
            }
        }
        else
        {
            set _outFile to testOut.
            set _doneFlag to true.
        }
    }
    // set _outFile to "0:/data/ref/unicodeCharCodes{0}.csv":Format("_" + fileStamp).
}

if bypassFlag
{
    print "BYPASS".
    print "------".
}
else
{
    print " - Output   : {0} ":Format(_outFile).
    print " - QuoteCols: {0} ":Format(_quoteColumns).
    print " - QuoteChar: {0} ":Format(_quoteChar).
    print " - Overwrite: {0} ":Format(overwriteFlag).

    if overwriteFlag
    {
        if exists(_outFile)
        {
            DeletePath(_outFile).
        }
    }
    wait 1.

    local logStr to "Code,Char".
    log logStr to _outFile.
    if _quoteColumns
    {
        set logStr to "{0}**0&&{0},{0}**1,1&&{0}":Format(_quoteChar):Replace("**","{"):Replace("&&", "}").
    }
    else
    {
        set logStr to "{0},{1,1}".
    }

    from { local i to Max(0, _rangeMin).} until i = _rangeMax step { set i to i + 1.} do
    {
        local chr to Char(i).
        if chr = "'"
        {
            set chr to chr:Replace("'","''").
        }
        if Mod(i, 30) = 0
        {
            print "       " at (29, 16).
        }

        if _onlyPosiLenChars
        {
            if chr:Length > 0
            {
                log logStr:Format(i, Char(i)) to _outFile.
                print "[{0,5}%] {1,6} | Processing: [ {2} ]     ":Format(Round((i / _rangeMax) * 100, 1), i, chr) at (0, 16).
            }
            else
            {
                print "[{0,5}%] {1,6} | Processing: [       ]     ":Format(Round((i / _rangeMax) * 100, 1), i, chr) at (0, 16).
            }
        }
        else
        {
            log logStr:Format(i, Char(i)) to _outFile.
            print "[{0,5}%] {1,6} | Processing: [ {2} ]     ":Format(Round((i / _rangeMax) * 100, 1), i, chr) at (0, 16).
        }
    }
    print "Complete!                        " at (0, 16).
}