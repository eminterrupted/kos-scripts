//Library for science
@lazyGlobal off.

local sciMod is "ModuleScienceExperiment".

//Delegates
    global get_sci_list is get_sci_modules_for_vessel@.


global function get_sci_modules_from_list {
    parameter pList.

    local retlist is list().
    
    for p in pList {
        if p:hasModule(sciMod) {
            retList:add(p:getModule(sciMod)).
        }
    }

    return retList.
}


global function get_sci_modules_for_vessel {
    return ship:modulesNamed(sciMod).
}


global function log_sci_list {
    parameter pList.

    for m in pList {
        if not (m:inoperable) {
            if not (m:hasData) {
                m:deploy().
                wait until m:hasData.
            }   
        }
    }
}

//this will keep the data unless it has a good transmit yield (50%+)
global function transmit_sci_list {
    parameter pList. 

    for m in pList {
        if m:hasData {
            transmit_sci(m).
            reset_sci(m).
        }
    }
}


global function transmit_sci {
    parameter m.

    for data in m:data {
        if data:transmitValue > 0 and data:transmitValue = data:scienceValue {
            set errLvl to 0.
            logStr("[recover science] Transmitting science").
            m:transmit().
        }

        else if data:transmitValue < data:scienceValue {
            set errLvl to 2.
            logStr("[recover science] Ideal recovery method is recover, not transmit", errLvl).
        }

        else if data:transmitValue = 0 {
            set errLvl to 1.
            logStr("[recover science] No science value from transmitting data", errLvl).
        }
    }
}


global function recover_sci {
    parameter m.

    for data in m:data {
        if data:transmitValue > 0 {
            set errLvl to 0.
            logStr("[recover science] Transmitting science").
            m:transmit().
        }

        else if data:transmitValue < data:scienceValue {
            set errLvl to 2.
            logStr("[recover science] Ideal recovery method is recover, not transmit", errLvl).
        }

        else if data:transmitValue = 0 {
            set errLvl to 1.
            logStr("[recover science] No science value from transmitting data", errLvl).
        }
    }
}

global function reset_sci {
    parameter m.

    if not (m:inoperable) m:reset().
}