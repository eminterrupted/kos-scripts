//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/part/lib_antenna.ks").

local containMod is "ModuleScienceContainer".
local dmagMod is "DMModuleScienceAnimate".
local sciMod is "ModuleScienceExperiment".
local sciList is list().

//-- Global functions --//
    //Deploy without running the experiment - useful for matbay, goo, etc
    global function deploy_sci_list {
        parameter mList.

        for m in mList {
            deploy_sci_mod(m).
        }
    }


    global function get_sci_list {
        parameter pList.

        return get_sci_mod_for_parts(pList).
    }


    //Gets all science modules in the given parts, defaults to vessel
    global function get_sci_mod_for_parts {
        parameter pList.
        
        set sciList to list().
        set dmagMod to "DMModuleScienceAnimate".
        set sciMod to "ModuleScienceExperiment".

        for p in pList {
            if p:hasModule(sciMod) sciList:add(p:getModule(sciMod)).
            else if p:hasModule(dmagMod) sciList:add(p:getModule(dmagMod)).
        }

        return sciList.
    }


    //Logs science experiments in a given set of modules
    global function log_sci_list {
        parameter mList.

        if mList:length > 0 {
            for m in mList {
                log_sci(m).
            }
        }
    }

    //this will keep the data unless it has a good transmit yield (50%+)
    global function recover_sci_list {
        parameter mList, 
                transmitAlways is false.

        for m in mList {
            if m:hasData {
                recover_sci(m, transmitAlways).
            }
        }
    }


    //Resets all science experiments in a list
    global function reset_sci_list {
        parameter mlist.

        for m in mList reset_sci(m).
    }


//-- Local functions --//

    //Collect science into a container if one is present on board
    global function collect_sci_in_container {
        if ship:modulesNamed(containMod):length > 0 {
            local pm to ship:modulesNamed(containMod)[0].
            if pm:hasAction("collect all") pm:doAction("collect all", true).
            logStr("[collect_sci_in_container] Data collected in science container").
            return true.
        }

        else return false.
    }


    //Deploys science experiements - not to be confused with actually running them or deploy()!
    local function deploy_sci_mod {
        parameter m.
        
        if m:name = sciMod {
            if m:hasAction("toggle cover") m:doAction("toggle cover", true).
            else if m:hasEvent("open doors") m:doEvent("open doors").
            
            if m:hasField("status") wait until m:getField("status") = "Locked".
        }

        else if m:name = dmagMod {
            for a in m:allActions {
                if a:contains("deploy") m:doAction(a:replace("(callable) ",""):replace(", is KSPAction",""), true).
                wait until m:deployed.
            }
        }
    }


    //Returns the power required to transmit the provided data based on the ship's antenna power requirements
    local function get_sci_ec_req {
        parameter dat.

        local commObj is lex().
        for a in ship:partsTaggedPattern("comm.") {
            set commObj to get_antenna_fields(a).
            if commObj:hasKey("science packet size") {
                if commObj["status"] = "Connected" break.
            }
            set commObj to lex().
        }

        return ((dat:dataAmount / commObj["science packet size"]:replace(" Mits",""):toNumber) * commObj["science packet cost"]:replace(" charge",""):toNumber) * 1.5.
    }


    //Logs science experiment for a given module
    local function log_sci {
        parameter m. 

        if not m:inoperable {
            if not m:hasData {
                //deploy_sci_mod(m).
                m:deploy().
                wait until m:hasdata.
                addons:career:closedialogs().
            }
        }
    }

    //Transmits if transmission is ideal recovery method, else will keep science. 
    local function recover_sci {
        parameter m,
                  alwaysTransmit is false.

        //Get the data from the part
        for data in m:data {

            set errLvl to 0.
            local minEc is get_sci_ec_req(data).

            //If transmit flag is set, immediately transmit regardless of science value. Else, check sci val and exec accordingly
            if alwaysTransmit {
                logStr("[recover_sci] alwaysTransmit: True").
                transmit_on_connection(m, minEc).
            }

            //If science can be recovered from the experiment via transmission, do that
            else if data:transmitValue = data:scienceValue {
                transmit_on_connection(m, minEc).
            }

            else if data:transmitValue > 0 and data:transmitValue < data:scienceValue {
                if collect_sci_in_container() {
                    logStr("[recover_sci] Science collected").
                } else {
                    set errLvl to 1.
                    logStr("[recover sci] No container found aboard, storing data in experiment part").
                }
            }

            //If no science from transmit but available via recover, store
            else if data:transmitValue = 0 and data:scienceValue > 0 {
                logStr("[recover_sci] No science from transmit, only recover [" + data:title + "]", errLvl).
                if collect_sci_in_container() {
                    logStr("[recover_sci] Science collected").
                } else {
                    set errLvl to 1.
                    logStr("[recover_sci] No container found aboard, storing data in experiment part").
                }
            }

            //If no data available, silently fail
            else if data:scienceValue = 0 {
                set errLvl to 1.
                logStr("[recover_sci] No science value from experiment, resetting [" + data:title  + "]", errLvl).
                reset_sci(m).
            }
        }
    }


    //Resets science parts
    local function reset_sci {
        parameter m.
        if not (m:inoperable) m:reset().
        if m:deployed {
            if m:hassuffix("TOGGLE") m:toggle().
        }
    }

    local function transmit_on_connection {
        parameter m, minEc.

        logStr("[transmit_on_connection] Transmitting when connection to KSC established").
        when addons:rt:hasKscConnection(ship) then transmit_data(m, minEc).
    }

    //Transmits science
    local function transmit_data {
        parameter m, minEc.

        for data in m:data {
            //Sets up a trigger to transmit when available EC is above threshold. This usually fires right away.
            when ship:electricCharge > minEc then {
                m:transmit().
                wait until not m:hasData. 
                set errLvl to 0.
                logStr("MinEC met, " + data:dataAmount + " science data transmitted from experiment [" + data:title + "]", errLvl).
            }
        }
    }