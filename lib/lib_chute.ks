@lazyGlobal off.

runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").

// Parachute functions
    global function arm_chutes 
    {
        parameter pList is ship:parts.

        local chuteMod is "RealChuteModule".

        for p in pList 
        {
            if p:hasModule(chuteMod) 
            {
                do_event(p:getModule(chuteMod), "arm parachute").
            }
        }
    }