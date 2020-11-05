@lazyGlobal off.


//SCANsat 

    //Basic functions
    global function start_scansat_multi {
        parameter p.

        local m is p:getModule("SCANsat").
        if m:hasEvent("start scan: multispectral") m:doEvent("start scan: multispectral").
    }

    global function stop_scansat_multi {
        parameter p.

        local m is p:getModule("SCANsat").
        if m:hasEvent("stop scan: multispectral") m:doEvent("stop scan: multispectral").
    }

    //-- return if scanner is at ideal altitude for scanner type
    global function check_scansat_alt {
        parameter p.

        local scanAlt is get_scansat_alt(p).
        
        if ship:altitude > scanAlt["max"] return 3.         // too high
        else if ship:altitude > scanAlt["ideal"] return 2.  // ideal
        else if ship:altitude > scanAlt["min"] return 1.    // ok
        else return 0.                                      // too low
    }


    //Formats the altitude string to return an object containing min, max, and ideal values.
    global function get_scansat_alt {
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
        if retObj:hasKey("surface in daylight") set retObj["surface in daylight"] to m:getField("surface in daylight"):substring(15,1).
        
        return retObj.
    }


    //Sets up a trigger to turn off the scanner if surface is in darkness
    global function schedule_scan_by_daylight {
        parameter p,
                  pScanType.

        local m is p:getModule("SCANsat").
        local srfLight is "". 

        if m:hasField("surface in daylight") {
            lock srfLight to m:getField("surface in daylight"):substring(15,1).
            on srfLight {
                if srfLight = "V" {
                    if m:hasEvent("start scan: multispectral") m:doEvent("start scan: multispectral").
                } else {
                    if m:hasEvent("stop scan: multispectral") m:doEvent("stop scan: multispectral").
                }

                return true.
            }
        }
    }



//Procedural fairings
    //-- jettison fairing
    global function jettison_fairing {
        parameter m. 
        
        if m:isType("Part") set m to m:getModule("ProceduralFairingDecoupler").
        if m:hasEvent("jettison fairing") m:doEvent("jettison fairing").
    }


    //Fairing base decoupler
    global function decouple_fairing_base {
        parameter p.

        local m is p:getModule("ModuleDecouple").
        if m:hasEvent("decoupler staging") m:doEvent("decoupler staging").
    }


//shrouded decoupler
    //-- jettison shroud without decoupling
    global function jettison_decoupler_shroud {
        parameter p.

        local m is p:getModule("ModuleDecouplerShroud").
        if m:hasEvent("jettison") m:doEvent("jettison").
    }



//kOS Core Parts
    //Set RGB Values
    global function set_kos_rgb {
        parameter p,
                r is 0.45,
                g is 0.35,
                b is 0.75.

        local m is p:getModule("kOSLightModule").

        m:setField("light r", r).
        m:setField("light g", g).
        m:setField("light b", b).
    }



    //RGB!
    global function set_rgb_for_part {
        parameter p is 0,
                r is 0,
                g is 0,
                b is 0.

        return true.
    }