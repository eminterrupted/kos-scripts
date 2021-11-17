@lazyGlobal off.

//-- Dependencies --//
//#include "0:/lib/disp"
//#include "0:/lib/util"

local scanDelegates to ScansatDelegates().

//#region -- Actions
// Functions for the SCANsat addon from here: https://github.com/JonnyOThan/Kos-Scansat
global function ScansatActivate
{
    parameter scanner, state is true.

    local scanModule to scanner:getModule("SCANsat").
    local event      to choose "start scan:" if state else "stop scan:".
    local scanAction to GetEventFromModule(scanModule, event).

    return DoEvent(scanModule, scanAction).
}

// Retrieves science from a scansat
global function ScansatScience
{
    parameter scanner.

    local sciModule  to scanner:getModule("SCANexperiment").
    local sciAnalyze to GetEventFromModule(sciModule, "analyze data:").

    return DoEvent(sciModule, sciAnalyze).
}
//#endregion

//#region -- Utils
// Returns coverage for all scan types a scanner is capable of
global function ScansatCoverage
{
    parameter scanner.

    local scanObj  to lex().
    local typeList to scanner:getModule("SCANsat"):getField("scan type"):split(",").

    for type in typeList 
    {
        if type:contains("Alt Hi")              set scanObj[type] to addons:scansat:getCoverage(ship:body, "AltimetryHiRes").
        else if type:contains("Alt Lo")         set scanObj[type] to addons:scansat:getCoverage(ship:body, "AltimetryLoRes").
        else if type:contains("Anomaly")        set scanObj[type] to addons:scansat:getCoverage(ship:body, "Anomaly").
        else if type:contains("AnomalyDetail")  set scanObj[type] to addons:scansat:getCoverage(ship:body, "AnomalyDetail").
        else if type:contains("Biome")          set scanObj[type] to addons:scansat:getCoverage(ship:body, "Biome").
        else if type:contains("Res Hi")         set scanObj[type] to addons:scansat:getCoverage(ship:body, "ResourceHiRes").
        else if type:contains("Res Lo")         set scanObj[type] to addons:scansat:getCoverage(ship:body, "ResourceLoRes").
        else if type:contains("Vis Hi")         set scanObj[type] to addons:scansat:getCoverage(ship:body, "VisualHiRes").
        else if type:contains("Vis Lo")         set scanObj[type] to addons:scansat:getCoverage(ship:body, "VisualLoRes").
    }

    return scanObj.
}

// A display for scansat scripts
global function DispScansat
{
    parameter scanner.
    
    local scanCov to ScansatCoverage(scanner).
    local line to 10.

    local function lcr
    {
        set line to line + 1.
        return line.
    }

    print "SCANSAT"                                                       at (0, line).
    print "-------"                                                       at (0, lcr()).
    print "SCANNER    : " + scanner:title                                 at (0, lcr()).
    print "SCAN TYPE  : " + scanDelegates:scanType(scanner)               at (0, lcr()).
    print "ALT RANGE  : " + scanDelegates:scanAlt(scanner)                at (0, lcr()).
    lcr().
    print "STATUS     : " + scanDelegates:scanStatus(scanner)   + "     " at (0, lcr()).
    print "SCAN FOV   : " + scanDelegates:scanFov(scanner)      + "     " at (0, lcr()). 
    print "SCAN POWER : " + scanDelegates:scanPower(scanner)    + "     " at (0, lcr()).
    print "DAYLIGHT   : " + scanDelegates:scanDaylight(scanner) + "     " at (0, lcr()).
    lcr().

    print "COVERAGE"                                                      at (0, lcr()).
    print "--------"                                                      at (0, lcr()).
    for key in scanCov:keys
    {
        print key:trim + " : " + round(scanCov[key], 2)                        at (0, lcr()).
    }
}

// Return a list of scansat delegates for use in display
global function ScansatDelegates
{
    local scanAlt       to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan altitude") return m:getField("scan altitude").}.
    local scanDaylight  to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("surface in daylight") return m:getField("surface in daylight").}.
    local scanFov       to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan fov") return m:getField("scan fov").}.
    local scanPower     to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan power") return m:getField("scan power").}.
    local scanStatus    to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan status") return m:getField("scan status").}.
    local scanType      to { parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan type") return m:getField("scan type").}.
    
    return lexicon("scanAlt",      scanAlt@,
                   "scanDaylight", scanDaylight@,
                   "scanFov",      scanFov@,
                   "scanPower",    scanPower@,
                   "scanStatus",   scanStatus@, 
                   "scanType",     scanType@
                   ).
}
//#endregion