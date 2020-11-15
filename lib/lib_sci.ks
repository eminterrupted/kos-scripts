//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").

local sciMod is "ModuleScienceExperiment".

//Gets all science modules on the vessel
global function get_sci_mod {
    return ship:modulesNamed(sciMod).
}

//Takes a list of parts, and returns all science modules
global function get_sci_modules_for_list {
    parameter pList.

    local retlist is list().
    
    for p in pList {
        if p:hasModule(sciMod) {
            retList:add(p:getModule(sciMod)).
        }
    }

    return retList.
}


global function log_sci {
    parameter m. 

    if not m:inoperable {
        if not m:hasData {
            m:deploy().
            wait until m:hasData.
            addons:career:closedialogs().
        }
    }
}

global function log_sci_list {
    parameter pList.

    for m in pList {
        log_sci(m).
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

//Transmits if transmission is ideal recovery method, else will keep science. 
global function transmit_sci {
    parameter m.

    for data in m:data {

        //Science value over 
        if data:transmitValue > 0 and data:transmitValue = data:scienceValue {
            set errLvl to 0.
            logStr("[transmit science] Transmitting science").
            m:transmit().
        }

        //Transmit val < science val - keep science
        else if data:transmitValue > 0 and data:transmitValue < data:scienceValue {
            //stow_sci_data().
            set errLvl to 2.
            logStr("[transmit science] Ideal recovery method is recover, not transmit", errLvl).
        }

        //If no data available for transmit, silently fail
        else if data:transmitValue = 0 {
            set errLvl to 1.
            logStr("[transmit science] No science value from transmitting data", errLvl).
        }
    }
}


global function reset_sci {
    parameter m.
    if not (m:inoperable) m:reset().
}