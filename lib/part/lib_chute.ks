@lazyGlobal off.

runOncePath("0:/lib/lib_core").

// Parachute functions
    global function arm_chutes {
        parameter pList is ship:parts.

        local chuteMod is "RealChuteModule".

        for p in pList {
            if p:hasModule(chuteMod) {
                local m is p:getModule(chuteMod).
                if m:hasEvent("arm parachute") m:doEvent("arm parachute").
            }
        }
    }