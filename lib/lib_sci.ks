//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/part/lib_antenna").

local containMod    is "ModuleScienceContainer".
local dmagMod       is "DMModuleScienceAnimate".
local sciMod        is "ModuleScienceExperiment".
local soilMod       is "DMSoilMoisture".
local hammerMod     is "DMSeismicHammer".
local seisPodMod    is "DMSeismicSensor".
local reconMod      is "DMReconScope".

local usSimpleMod   is "USSimpleScience".
local usAdvMod      is "USAdvancedScience".

local usActTemp     is "log temperature".
local usActBaro     is "log pressure data".
local usActGrav     is "log gravity data".
local usActSeis     is "log seismic data".
local usActMBay     is "observe materials bay".
local usActGoo      is "observe mystery goo".

local queuedEcSum is 0.
local sciList is list().
//local transmitQueue is queue().

//-- functions --//

//-- Arm and release seismic pods --//

    // Arms the dmag seismic pods, and then deploys them
    global function deploy_seismic_pods {
        local podList to ship:partsTaggedPattern("pod").
        if podList:length > 0 {
            for p in podList {
                p:getModule("DMSeismicSensor"):doAction("arm pod", true).
                p:getModule("ModuleAnchoredDecoupler"):doEvent("decouple").
            }
        }
    }

//-- Collect science in container --//
    
    // Collect science into a container if one is present on board
    // Returns true if container available and data collected
    // False if no container found
    global function collect_sci_in_container {
        if ship:modulesNamed(containMod):length > 0 {
            local pm to ship:modulesNamed(containMod)[0].
            if pm:hasAction("collect all") pm:doAction("collect all", true).
            logStr("[collect_sci_in_container] Data collected in science container").
            return true.
        }

        else return false.
    }

//-- Deploy science experiment doors and sensors --//

    //Deploy without running the experiment - useful for matbay, goo, etc
    global function deploy_sci_list {
        parameter mList.

        out_info("I'm in deploy_sci_list").
        
        for m in mList {
            if m:name = sciMod              toggle_sci_mod_st(m, true).
            else if m:name = dmagMod        toggle_sci_mod_dmag(m, true).
            else if m:name = usAdvMod       toggle_sci_mod_us(m, true).
            else if m:name = usSimpleMod    toggle_sci_mod_us(m, true).
            else if m:name = soilMod        toggle_sci_mod_dmag(m, true).
            else if m:name = hammerMod      toggle_sci_mod_dmag(m, true).
            else if m:name = seisPodMod     toggle_sci_mod_dmag(m, true).
            else if m:name = reconMod       toggle_sci_mod_dmag(m, true).
        }

        out_info().
    }


//-- Get electricCharge requirement for data transmission --//

    //Returns the power required to transmit the provided data based on the ship's antenna power requirements
    local function get_sci_ec_req {
        parameter _d.

        local commObj is lex().
        for a in ship:partsTaggedPattern("comm.") {
            set commObj to get_antenna_fields(a).
            if commObj:hasKey("science packet size") {
                if commObj["status"] = "Connected" break.
            }
            set commObj to lex().
        }

        return ((_d:dataAmount / commObj["science packet size"]:replace(" Mits",""):toNumber) * commObj["science packet cost"]:replace(" charge",""):toNumber) * 1.5.
    }

//-- Get science modules on ship --//

    // Takes a list of parts and returns sci modules for it
    global function get_sci_list {
        parameter pList.

        return get_sci_mod_for_parts(pList).
    }


    local function get_sci_mod_multi_for_part {
        parameter _p,
                  _m.
        
        from { local idx to 0.} until idx = (_p:modules:length - 1) step {set idx to idx + 1.} do {
            if _p:getModuleByIndex(idx):name = _m {
                sciList:add(_p:getModuleByIndex(idx)).
            }
        }
    }


    // Helper that calls get_sci_mod_for_parts with all parts on vessel
    global function get_sci_mod {
        return get_sci_mod_for_parts(ship:parts).
    }


    //Gets all science modules in the given parts
    global function get_sci_mod_for_parts {
        parameter pList.
        
        set sciList to list().

        for p in pList {
            if p:hasModule(sciMod) {
                sciList:add(p:getModule(sciMod)).
            } else if p:hasModule(dmagMod) {
                sciList:add(p:getModule(dmagMod)).
            } else if p:hasModule(usAdvMod) {
                get_sci_mod_multi_for_part(p, usAdvMod).
            } else if p:hasModule(usSimpleMod) {
                get_sci_mod_multi_for_part(p, usSimpleMod).
            } else if p:hasModule(soilMod) {
                sciList:add(p:getModule(soilMod)).
            } else if p:hasModule(hammerMod) {
                sciList:add(p:getModule(hammerMod)).
            } else if p:hasModule(seisPodMod) {
                sciList:add(p:getModule(seisPodMod)).
            } else if p:hasModule(reconMod) {
                sciList:add(p:getModule(reconMod)).
            }
        }

        return sciList.
    }

    global function get_us_mod {
        set sciList to list().

        for m in ship:modulesNamed(usSimpleMod) {
            sciList:add(m).
        }

        for m in ship:modulesNamed(usAdvMod) {
            sciList:add(m).
        }

        return sciList.
    }



//-- Log science data in experiments --//
    local function log_recon {
        parameter m.

        if ship:latitude > 0 {
            if from_cache("recon_north") <> "null" {
                m:deploy().
                to_cache("recon_north", true).
            }
        } else {
            if from_cache("recon_south") <> "null" {
                m:deploy().
                to_cache("recon_south", true).
            }
        }
    }


    //Logs science experiment for a given module
    local function log_sci {
        parameter m. 

        if not m:inoperable {
            if not m:hasData {
                if m:name <> reconMod {
                    m:deploy().
                    wait until m:hasData.
                    addons:career:closedialogs().
                } else if m:name = reconMod {
                    log_recon(m). 
                }
            }
        }
    }

    // Logs science experiments in a given set of modules
    // Gives up to 2 seconds for science to be recorded, then
    // moves on to the next item in the list
    global function log_sci_list {
        parameter mList.

        if mList:length > 0 {
            for m in mList {
                if m:name = usSimpleMod or m:name = usAdvMod {
                    log_sci_us(m).
                } else {
                    log_sci(m).
                }
            }
        }
    }

    // Logs science experiment for a USI module
    // These are special because the "Deploy" command does not work here
    local function log_sci_us {
        parameter m.

        print m:name at (2, 8).

        if m:hasAction(usActTemp) m:doAction(usActTemp, true).
        else if m:hasAction(usActBaro) m:doAction(usActBaro, true).
        else if m:hasAction(usActGrav) m:doAction(usActGrav, true).
        else if m:hasAction(usActSeis) m:doAction(usActSeis, true).
        else if m:hasAction(usActMBay) m:doAction(usActMBay, true).
        else if m:hasAction(usActGoo)  m:doAction(usActGoo,  true).

        addons:career:closedialogs().
    }


//-- Retract science doors / sensors --//

    //Retracts all science module doors and parts
    global function retract_sci_list {
        parameter mList.

        for m in mList {
            if m:name = sciMod              toggle_sci_mod_st(m, false).
            else if m:name = dmagMod        toggle_sci_mod_dmag(m, false).
            else if m:name = usAdvMod       toggle_sci_mod_us(m, false).
            else if m:name = usSimpleMod    toggle_sci_mod_us(m, false).
            else if m:name = soilMod        toggle_sci_mod_dmag(m, false).
        }
    }



//-- Toggle science doors / sensors --//

    //Toggles the doors / sensors on a science experiment
    local function toggle_sci_mod_st {
        parameter _m,
                  _openMode.
        
        if _m:name = sciMod {
            if _m:hasAction("toggle cover") {
                _m:doAction("toggle cover", true).
                wait until _m:deployed = _openMode.
            } else if _m:hasEvent("open doors") {
                _m:doEvent("open doors").
                wait until _m:deployed = _openMode.
            }
        }
    }


    local function toggle_sci_mod_dmag {
        parameter _m,
                  _openMode.

        for a in _m:allActions {
            if a:contains("deploy") {
                _m:doAction(a:replace("(callable) ",""):replace(", is KSPAction",""), true).
                wait until _m:deployed = _openMode.
            }
        }
    }
        
    local function toggle_sci_mod_us {
        parameter _m,
                  _openMode.
                
        
        for a in _m:allActions {
            if a:contains("toggle") {
                _m:doAction(a:replace("(callable ", ""):replace(", is KSPAction", ""), true).
                wait until _m:deployed = _openMode.
            }
        }
    }



//-- Recover sci --///

    // Recovers science for a given module.
    // Allows transmit override for contracts via _alwaysTransmit
    // Works in two ways - 
    //   1. Adds experiments to the data transmission queue if 
    //      transmission is ideal recovery method. Sends tranmission 
    //      request to transmit_data_queue
    //   2. If tranmission not ideal, will attempt to keep science
    //      if container found.  
    local function recover_sci {
        parameter _m,
                  _alwaysTransmit is false.

        // Get the data from the part
        for data in _m:data {

            set errLvl to 0.
            local minEc is get_sci_ec_req(data).

            // If transmit flag is set, immediately transmit regardless of science value. Else, check sci val and exec accordingly
            if _alwaysTransmit {
                logStr("[recover_sci] alwaysTransmit: True").
                transmit_on_connection(_m, minEc).
            }

            // If science can be recovered from the experiment via transmission, do that
            else if data:transmitValue > 0 and data:transmitValue = data:scienceValue {
                logStr("[recover_sci] Transmit value [" + data:transmitValue + "] above threshold [" + data:title + "]").
                transmit_on_connection(_m, minEc).
            }

            // else if data has some science value and as established above, 
            // no tranmission value, stow in container
            else if data:scienceValue > 0 {
                logStr("[recover_sci] No or reduced science from transmit, attempting to recover in container [" + data:title + "]", errLvl).
                if collect_sci_in_container() {
                    logStr("[recover_sci] Science collected").
                } else {
                    set errLvl to 2.
                    logStr("[recover_sci] No container found aboard, resetting experiment.").
                    reset_sci(_m).
                }
            }

            else {
                set errLvl to 2.
                logStr("[recover_sci] No science value from experiment, resetting [" + data:title + "]", errLvl).
                reset_sci(_m).
            }
        }
    }


    //this will keep the data unless it has a good transmit yield (50%+)
    global function recover_sci_list {
        parameter _mList, 
                  _transmitAlways is false.

        for m in _mList {
            if m:hasData {
                recover_sci(m, _transmitAlways).
            }
        }
    }


//-- Reset part experiments --//
    //Resets science parts
    local function reset_sci {
        parameter _m.

        if _m:name = usAdvMod or _m:name = usSimpleMod {
            reset_us_sci_mod(_m).
        } else {                        // Stock and DMag modules
             _m:reset().
        }

        // if the module is deployed, undeploy it.
        if _m:deployed { 
            if _m:hassuffix("toggle") _m:toggle().
        }
    }


    //Resets all science experiments in a list
    global function reset_sci_list {
        parameter _mlist.

        for m in _mlist reset_sci(m).
    }

    //Resets all us science mod functions, which are 
    //special
    local function reset_us_sci_mod {
        parameter _m.

        if not _m:hasData return false.

        if _m:hasEvent("reset goo canister") {
            _m:doEvent("reset goo canister").
            _m:doEvent("retract goo bay").
        } else if _m:hasAction("reset materials bay") {
            _m:doAction("reset materials bay", true).
            _m:doAction("toggle bay doors", true).
        } else if _m:hasAction("log temperature") {
            _m:doAction("delete data", true). 
            _m:doAction("toggle thermometer", true).
        } else if _m:hasAction("log pressure data") {
            _m:doAction("delete data", true).
            _m:doAction("toggle barometer", true).
        } else if _m:hasAction("log seismic data") {
            _m:doAction("delete data", true).
            _m:doAction("toggle accelerometer", true).
        } else if _m:hasAction("log gravity data") {
            _m:doAction("delete data", true).
            _m:doAction("toggle gravioli", true).
        }
    }

//-- Transmit data --//



    //Transmits science
    local function transmit_data {
        parameter _m, 
                  _minEc.

        for data in _m:data {

            // Sets up a trigger to transmit when available EC is above threshold. 
            // If ship already has enough ec available, fires right away.
            when ship:electricCharge > _minEc then {
                _m:transmit().
                wait until not _m:hasData. 
                set queuedEcSum to queuedEcSum - _minEc.
                set errLvl to 0.
                logStr("MinEC met, " + data:dataAmount + " science data transmitted from experiment [" + data:title + "]", errLvl).
            }
        }
    }

    // Sets up a trigger to transmit science once a connection to KSC has been established
    // Adds the required _minEc to the queuedEcSum variable to 
    local function transmit_on_connection {
        parameter _m,
                  _minEc.

        logStr("[transmit_on_connection] Transmitting when connection to KSC established").
        when addons:rt:hasKscConnection(ship) then {
            set queuedEcSum to queuedEcSum + _minEc.
            
            transmit_data(_m, _minEc).
        }
    }