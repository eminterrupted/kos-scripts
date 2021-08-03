@lazyGlobal off.

//-- File management functions --//
// For brevity, this library does not use a namespace

// Alias for executing a script.
global function exec
{
    parameter filePath.
    runPath(filePath).
}

// Alias for loading a set of libraries. Takes a list of
// library names. Loads from local if file exists there, 
// else attempts to upload from archive. If not enough space,
// loads from the archive.
global function load
{
    parameter lib.
    
    if exists("local:/lib/" + lib) 
    {
        runOncePath("local:/lib/" + lib).
    }
    else
    {
        runOncePath(upload("/lib/" + lib, "local")).
    }
}

global function upload
{
    parameter filePath,
              tgtVol is "local".

    local srcPath to "0:"   + filePath.
    local tgtPath to tgtVol + ":" + filePath.

    if not (exists(tgtPath))
    {
        compile(srcPath) to tgtPath.
        if not (exists(tgtPath))
        {
            print "Unable to upload " + srcPath + " to " + tgtVol at (2, 25).
            wait 1.
            print ("Waiting for KSC connection to run from archive"):padRight(terminal:width) at (2, 25).
            wait until addons:rt:hasKscConnection(ship).
            return srcPath.
        }
        else
        {
            return tgtPath.
        }
    }
    return tgtPath.
}