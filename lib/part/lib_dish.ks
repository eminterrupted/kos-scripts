@lazyGlobal off.

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