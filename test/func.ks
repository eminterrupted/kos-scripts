@lazyGlobal off.
clearScreen.

parameter p0 to "".


runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/launch").

// local testFile to Path("0:/test/runFiles/testFile.ks").
// if exists(testFile) deletePath(testFile).
// log "print " + funcToTest + "." to testFile.

print "FUNCTIONAL TEST SCRIPT    v0.000001a".
print "====================================".
print " ".
print "Testing function: GetPartSetCount()".
print CheckPartSet(p0).

//runPath(testFile).

// -- cleanup --//
//deletePath(testFile).

//print CheckPartSet(params:join(""",""")).

local function GetPartSetCount
{
    parameter setTag is "".

    local pCount to 0.
    local pList to list().
    local stepCount to 0.

    if setTag = ""
    {
        set pList to ship:parts.
    }
    else
    {
        set pList to ship:partsTaggedPattern(setTag + ".*\.{1}\d+").
    }

    for p in pList
    {
        local parsedTag to p:Tag:Split(".").
        //local stepIdx to p:tag:LastIndexOf(".").
        //local step to p:Tag:Substring(stepIdx + 1, p:tag:length - stepIdx - 1).
        if parsedTag:length > 0 
        {
            local step to parsedTag[parsedTag:length - 1]:toNumber(0).
            set stepCount to max(stepCount, step).
        }
        if p:hasModule("ModuleAnimateGeneric") or p:hasModule("USAnimateGeneric") // Generic and bays
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleRTAntenna")   // RT Antennas
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleDeployableSolarPanel")    // Solar panels
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleResourceConverter") // Fuel Cells
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleGenerator") // RTGs
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleDeployablePart")  // Science parts / misc
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleRoboticServoHinge")
        {
            set pCount to pCount + 1.
        }
        else if p:hasModule("ModuleRoboticServoRotor")
        {
            set pCount to pCount + 1.
        }
    }

    return list(pCount, stepCount).
}