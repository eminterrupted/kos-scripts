@lazyGlobal off.

//shrouded decoupler
    //-- jettison
    global function jettison_decoupler_shroud {
        parameter p.

        local m is p:getModule("ModuleDecouplerShroud").
        if m:hasEvent("jettison") m:doEvent("jettison").
    }


//Dish antenna

    //dish target
    global function set_dish_target {
        parameter p,
                pTarget.

        local mod is "ModuleRTAntenna".

        local m is p:getModule(mod).
        m:setField("target",pTarget).
    }

    global function get_dish_target {
        parameter p.

        local m is p:getModule("ModuleRTAntenna").
        return m:getField("target").
    }
//--



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