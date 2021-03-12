@lazyGlobal off.

runOncePath("0:/lib/lib_util").

local scanDelegates to scansat_field_delegates().

// Functions for the SCANsat addon from here: https://github.com/JonnyOThan/Kos-Scansat
global function scansat_activate
{
    parameter scanner, state is true.

    local scanModule to scanner:getModule("SCANsat").
    local event      to choose "start scan:" if state else "stop scan:".
    local scanAction to util_event_from_module(scanModule, event).

    return util_do_event(scanModule, scanAction).
}


// A display for scansat scripts
global function scansat_disp
{
    parameter scanner.
    
    local covLine to 18.
    local scanCov to scansat_coverage(scanner).

    print "SCANSAT"                                                       at (0, 2).
    print "-------"                                                       at (0, 3).
    print "VESSEL     : " + ship:name                                     at (0, 4).
    print " "                                                             at (0, 5).
    print "SCANNER    : " + scanner:Title                                 at (0, 6).
    print "SCAN TYPE  : " + scanDelegates:scanType(scanner)               at (0, 7).
    print "ALT RANGE  : " + scanDelegates:scanAlt(scanner)                at (0, 8).
    print " "                                                             at (0, 9).
    print "STATUS     : " + scanDelegates:scanStatus(scanner)   + "     " at (0, 10).
    print "SCAN FOV   : " + scanDelegates:scanFov(scanner)      + "     " at (0, 11). 
    print "SCAN POWER : " + scanDelegates:scanPower(scanner)    + "     " at (0, 12).
    print "DAYLIGHT   : " + scanDelegates:scanDaylight(scanner) + "     " at (0, 13).
    print " "                                                             at (0, 14).
    print " "                                                             at (0, 15).
    print "COVERAGE"                                                      at (0, 16).
    print "--------"                                                      at (0, 17).
    for key in scanCov:keys
    {
        print key:trim + " : " + round(scanCov[key], 2)                        at (0, covLine).
        set covLine to covLine + 1.
    }
}


// Returns coverage for all scan types a scanner is capable of
global function scansat_coverage
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


// Return a list of scansat delegates for use in display
global function scansat_field_delegates
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


// Retrieves science from a scansat
global function scansat_science
{
    parameter scanner.

    local sciModule  to scanner:getModule("SCANexperiment").
    local sciAnalyze to util_event_from_module(sciModule, "analyze data:").

    return util_do_event(sciModule, sciAnalyze).
}