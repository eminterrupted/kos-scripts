//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/part/lib_antenna.ks").

local sciMod is "ModuleScienceExperiment".
local containMod is "ModuleScienceContainer".

//Collect science into a container if one is present on board
global function collect_sci_container {
    if ship:modulesNamed(containMod):length > 0 {
        local pm to ship:modulesNamed(containMod)[0].
        if pm:hasAction("collect all") pm:doAction("collect all", true).
        return true.
    }

    else return false.
}

//Deploy without running the experiment - useful for matbay, goo, etc
global function deploy_sci_list {
    parameter mList.

    for m in mList {
        deploy_sci_mod(m).
    }
}


global function deploy_sci_mod {
    parameter m.
    
    if m:part:hasModule(sciMod) {
        local pm to m:part:getModule(sciMod).
        if pm:hasAction("toggle cover") m:doAction("toggle cover", true).
        else if pm:hasEvent("open doors") m:doEvent("open doors").
        
        if pm:hasField("status") wait until pm:getField("status") = "Locked".
    }
}



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
            local sciTStamp to time:seconds + 5. 
            wait until m:hasdata or time:seconds > sciTStamp.
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
global function recover_sci_list {
    parameter pList. 

    for m in pList {
        if m:hasData {
            recover_sci(m).
        }
    }
}

//Transmits if transmission is ideal recovery method, else will keep science. 
global function recover_sci {
    parameter m.

    for data in m:data {

        //Science value over 
        if data:transmitValue > 0 and data:transmitValue = data:scienceValue {
            set errLvl to 0.
            logStr("[transmit science] Transmitting science").
            local minEc is get_sci_ec_req(data).
            if ship:electricCharge > minEc {
                m:transmit().
                logStr(data:dataAmount + " science data transmitted from experiment [" + data:title + "]").
            } else {
                set errLvl to 1.
                logStr("Not enough electric charge [" + ship:electricCharge + " / " + minEc + "] to transmit " + data:dataAmount + " science data from experiment [" + data:title + "]", errLvl).
                if collect_sci_container() {
                    set errLvl to 0.
                    logStr("Container found, storing " + data:dataAmount + " science data from experiment [" + data:title + "]", errLvl).
                }

                else {
                    set errLvl to 2.
                    logStr("No container found! Experiment will be held until enough EC is available", errLvl).
                    when ship:electricCharge > minEc then {
                        m:transmit().
                        set errLvl to 0.
                        logStr("MinEC met, " + data:dataAmount + " science data transmitted from experiment [" + data:title + "]", errLvl).
                    }
                }
            }
        }

        //Transmit val < science val - keep science and try to collect into a container
        else if data:transmitValue < data:scienceValue {
            //stow_sci_data().
            set errLvl to 1.
            logStr("[transmit science] Ideal recovery method is recover, not transmit", errLvl).
            if collect_sci_container() {
                set errLvl to 0. 
                logStr("[transmist science] Science Container found, collecting").
            } else {
                logStr("[transmit science] No container found aboard, must recover this part to recover data").
            }
        }

        //If no data available, silently fail
        else if data:scienceValue = 0 {
            set errLvl to 2.
            logStr("[transmit science] No science value from experiment", errLvl).
            reset_sci(m).
        }
    }
}


global function reset_sci_list {
    parameter mlist.

    for m in mList reset_sci(m).
}


global function reset_sci {
    parameter m.
    if not (m:inoperable) m:reset().
}

local function get_sci_ec_req {
    parameter dat.
    local commObj is lex().
    for a in ship:partsTaggedPattern("comm.") {
        set commObj to get_antenna_fields(a).
        if commObj["status"] = "Connected" break.
    }

    return ((dat:dataAmount / commObj["science packet size"]:replace(" Mits",""):toNumber) * commObj["science packet cost"]:replace(" charge",""):toNumber) * 1.5.
}