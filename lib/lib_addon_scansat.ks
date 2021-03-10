@lazyGlobal off.

// Functions for the SCANsat addon from here: https://github.com/JonnyOThan/Kos-Scansat
global function scansat_activate
{
    parameter scanner, state is true.

    local scanModule    to "SCANsat".
    local startMulti    to "start scan: multispectral".
    local stopMulti     to "stop scan: multispectral".

    local m to scanner:getModule(scanModule).
    if state
    {
        if m:hasEvent(startMulti) m:doEvent(startMulti).
    }
    else
    {
        if m:hasEvent(stopMulti) m:doEvent(stopMulti).
    }
}

global function scansat_field_delegates
{
    local scanStatus    to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan status") return m:getField("scan status").}.
    local scanAlt       to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan altitude") return m:getField("scan altitude").}.
    local scanType      to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan type") return m:getField("scan type").}.
    local scanFov       to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan fov") return m:getField("scan fov").}.
    local scanPower     to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("scan power") return m:getField("scan power").}.
    local scanDaylight  to {parameter p. local m to p:getModule("SCANsat"). if m:hasField("surface in daylight") return m:getField("surface in daylight").}.
    
    return lexicon("scanStatus",   scanStatus@, 
                   "scanAlt",      scanAlt@, 
                   "scanType",     scanType@,
                   "scanFov",      scanFov@,
                   "scanPower",    scanPower@,
                   "scanDaylight", scanDaylight@
                   ).
}

global function scan_science
{
    parameter scanner.

    local scanSciModule to "SCANexperiment".
    local scanSciMulti  to "analyze data: multispectral".
    local m to scanner:getModule(scanSciModule).
    if m:hasEvent(scanSciMulti) m:doEvent(scanSciMulti).
    return m. 
}