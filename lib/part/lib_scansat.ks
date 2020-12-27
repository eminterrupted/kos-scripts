@lazyGlobal off.

//SCANsat 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_sci").

local scanMod is "SCANsat".
local expMod is "SCANexperiment".
local resMod is "ModuleSCANResourceScanner".

    //Basic functions
    global function start_scansat {
        parameter p.

        if p:hasModule(scanMod) {
            local m is p:getModule(scanMod).
            if m:hasEvent("start scan: multispectral")  m:doEvent("start scan: multispectral").
            else if m:hasEvent("start scan: radar")     m:doEvent("start scan: radar").
            else if m:hasEvent("start scan: sar")       m:doEvent("start scan: sar").
            else if m:hasEvent("start scan: visual")    m:doEvent("start scan: visual").
            else if m:hasEvent("start scan: resource")  m:doEvent("start scan: resource").
        }

        if p:hasModule(resMod) {
            local m is p:getModule(resMod).
            if m:hasEvent("start scan: resource")       m:doEvent("start scan: resource").
        }
    }
    

    global function stop_scansat{
        parameter p.

        local m is p:getModule(scanMod).
        if m:hasEvent("stop scan: multispectral")   m:doEvent("stop scan: multispectral").
        else if m:hasEvent("stop scan: radar")      m:doEvent("stop scan: radar").
        else if m:hasEvent("stop scan: sar")        m:doEvent("stop scan: sar").
        else if m:hasEvent("stop scan: visual")     m:doEvent("stop scan: visual").
        else if m:hasEvent("stop scan: resource")  m:doEvent("stop scan: resource").
    }

    global function scansat_analyze_data {
        parameter p.

        local m is p:getModule(expMod).
        if m:hasAction("analyze data: multispectral")   m:doAction("analyze data: multispectral", true).
        else if m:hasEvent("analyze data: sar")         m:doEvent("analyze data: sar").
        else if m:hasEvent("analyze data: visual")      m:doEvent("analyze data: visual").
        else if m:hasEvent("analyze data: resource")      m:doEvent("analyze data: resource").

        recover_sci_list(list(m)).
    }

    //-- return if scanner is at ideal altitude for scanner type
    global function check_scansat_alt {
        parameter p.

        local scanAlt is get_scansat_alt_range(p).
        
        if ship:altitude > scanAlt["max"] return 3.         // too high
        else if ship:altitude > scanAlt["ideal"] return 2.  // ideal
        else if ship:altitude > scanAlt["min"] return 1.    // ok
        else return 0.                                      // too low
    }


    //Formats the altitude string to return an object containing min, max, and ideal values.
    global function get_scansat_alt_range {
        parameter p.

        local m is p:getModule("SCANsat").
        local altStr is m:getField("scan altitude").
        
        local altRange is altStr:split(":")[0]:trim.
        local idealAlt is (altStr:split(":")[1]:replace(">",""):replace("km",""):replace("ideal",""):trim:tonumber) * 10000.
        local minAlt is (altRange:split("-")[0]:replace("km"):trim:tonumber) * 10000.
        local maxAlt is (altRange:split("-")[1]:replace("km"):trim:tonumber) * 10000.

        return lexicon("min", minAlt, "max", maxAlt, "ideal", idealAlt).
    }


    //-- return scanner field data in object
    global function get_scansat_data {
        parameter p.

        local m is p:getModule("SCANsat").
        local retObj is lexicon().
        
        for f in m:allFieldNames {
            set retObj[f] to m:getField(f).
        }

    //surface in daylight field contains html color codes - strip it out
        if retObj:hasKey("surface in daylight") {
            set retObj["surface in daylight"] to choose retObj["surface in daylight"]:substring(15,1) if retObj["surface in daylight"]:length > 0 else "".
        }

        return retObj.
    }